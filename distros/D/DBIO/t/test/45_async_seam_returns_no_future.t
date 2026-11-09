use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k252 (4). Where core calls a transport seam that must hand back a
# Future, and hangs the connection's release off that Future, it guarded the
# call as
#
#   my $f = eval { $self->_seam(...) } // $fc->fail($@);
#
# so that a seam dying before it has a Future still takes the release (k229,
# k231, k237). A seam that returns undef WITHOUT dying slips through: the eval
# succeeded, $@ is empty, and the Future is failed with an empty error. Under
# DBIO::Test::Future that is a failure nobody can read; under Future.pm it is
# no Future at all -- Future.pm refuses a false exception and dies inside the
# caller, which on the pipeline path skipped the exit and the release.
#
# The claims:
#
#   * _seam_future hands back a seam's Future unchanged, and turns a throw into
#     a Future failed with the seam's error; a seam that returns undef or a
#     plain value becomes a Future failed with an error naming the backend and
#     the seam -- with DBIO::Test::Future and with Future.pm;
#   * on each path that dispatched through the old guard, a seam returning undef
#     fails the operation with that named error, and the connection comes back
#     exactly once: pipeline (_pipeline_sync), a transaction's ROLLBACK
#     (_query_async_pinned; the transaction's own error first), deploy_async on
#     a non-transactional engine (_execute_ddl_async) and a run the per-statement
#     hook declares non-transactional (_run_ddl_stmts_async).
#
# THE SUBSTITUTIONS: a fake wire over a real DBIO::Storage::PoolBase of size 1
# that records every release; each seam answers from a knob.

{
  package K252::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K252::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K252::Conn->new(++$_[0]->{_next_id}) }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }

  sub _retire_in_use_connection {
    my ($self, $conn) = @_;
    push @{ $self->{retire_log} }, $conn->{id};
    return $self->SUPER::_retire_in_use_connection($conn);
  }
}

# A transactional engine whose per-statement hook declares every statement
# non-transactional: deploy_async's outlier branch.
{
  package K252::LooseOwner;
  sub new { bless {}, $_[0] }
  sub _use_transactional_ddl { 1 }
  sub _ddl_statement_is_transactional { 0 }
}

# {answer}{SEAM}: what the seam returns instead of its Future.
{
  package K252::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{fc} }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _install_ddl     { "CREATE TABLE k252 (id int);" }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K252::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->{fc},
    );
  }

  sub _answers {
    my ($self, $seam) = @_;
    return exists $self->{answer}{$seam};
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    push @{ $self->{captured} }, $verb;
    return $self->{answer}{$verb} if $self->_answers($verb);
    return $self->future_class->fail("statement failed\n") if $verb eq 'INSERT';
    return $self->future_class->done;
  }

  sub _pipeline_enter { $_[1]->{in_pipeline} = 1; 1 }
  sub _pipeline_exit  { $_[1]->{in_pipeline} = 0; 1 }

  sub _pipeline_sync {
    my ($self) = @_;
    return $self->{answer}{_pipeline_sync} if $self->_answers('_pipeline_sync');
    return $self->future_class->done;
  }

  sub _execute_ddl_async {
    my $self = shift;
    return $self->{answer}{_execute_ddl_async} if $self->_answers('_execute_ddl_async');
    return $self->next::method(@_);
  }

  sub _run_ddl_stmts_async {
    my $self = shift;
    return $self->{answer}{_run_ddl_stmts_async} if $self->_answers('_run_ddl_stmts_async');
    return $self->next::method(@_);
  }

  # A seam of the helper's own test: answers with its arguments' first element.
  sub _k252_seam {
    my ($self, $what) = @_;
    die "k252 seam died\n" if $what eq 'die';
    return $what eq 'undef' ? undef : $what;
  }
}

sub new_backend {
  my ($fc, %knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K252::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{fc}       = $fc;
  $backend->{captured} = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

# (value, error) of a settled Future, the error as it failed with it -- the
# same way for DBIO::Test::Future and Future.pm.
sub outcome {
  my ($f) = @_;
  return (undef, 'pending') unless $f->is_ready;
  my ($value, $error);
  my $fc = ref $f;
  my $seen = $f->then(
    sub { $value = $_[0]; return $fc->done },
    sub { $error = $_[0]; return $fc->done },
  );
  return ($value, $error);
}

# The operation answered through a failed Future, not an exception, naming the
# seam; and the connection came back exactly once.
sub fails_naming_and_releases {
  my ($backend, $run, $want, $label, $retired) = @_;
  my $f;
  my $lived = eval { $f = $run->(); 1 };
  ok $lived, "$label: answers through its Future, it does not throw" or diag $@;
  return unless $lived;
  my (undef, $error) = outcome($f);
  like "$error", $want, "$label: fails with an error naming the seam";
  is_deeply $backend->pool->{ $retired ? 'retire_log' : 'release_log' }, [ 1 ],
    "$label: the connection " . ($retired ? 'was retired' : 'came back') . " exactly once";
  my $next = $backend->pool->acquire;
  ok $next->is_ready, "$label: the next acquire resolves";
}

my @future_classes = ('DBIO::Test::Future');
push @future_classes, 'Future' if eval { require Future; 1 };
note 'Future.pm not installed: checked with DBIO::Test::Future only'
  if @future_classes == 1;

for my $fc (@future_classes) {
  # -------------------------------------------------------------------------
  # _seam_future itself.
  # -------------------------------------------------------------------------
  {
    my $backend = new_backend($fc);
    my $given = $fc->done('k252');
    is $backend->_seam_future(_k252_seam => $given), $given,
      "$fc: _seam_future hands a seam's Future back unchanged";

    for my $case (
      [ die   => qr/^k252 seam died$/ ],
      [ undef => qr/^K252::Backend->_k252_seam returned undef, not a Future/ ],
      [ plain => qr/^K252::Backend->_k252_seam returned no Future/ ],
    ) {
      my ($what, $want) = @$case;
      my $f = eval { $backend->_seam_future(_k252_seam => $what) };
      ok $f && $f->is_ready && $f->is_failed,
        "$fc: _seam_future, a seam that answers $what: a failed Future" or diag $@;
      next unless $f;
      my (undef, $error) = outcome($f);
      like "$error", $want, "$fc: ... failed with " . ($what eq 'die' ? "the seam's error" : 'an error naming the seam');
    }
  }

  # -------------------------------------------------------------------------
  # pipeline: _pipeline_sync returns undef.
  # -------------------------------------------------------------------------
  {
    my $backend = new_backend($fc, answer => { _pipeline_sync => undef });
    fails_naming_and_releases($backend, sub { $backend->pipeline(sub { 1 }) },
      qr/_pipeline_sync returned undef, not a Future/, "$fc, pipeline", 1);
  }

  # -------------------------------------------------------------------------
  # A transaction's ROLLBACK dispatch returns undef.
  # -------------------------------------------------------------------------
  {
    my $backend = new_backend($fc, answer => { ROLLBACK => undef });
    fails_naming_and_releases($backend,
      sub { $backend->txn_do_async(sub { die "coderef died\n" }) },
      qr/Transaction aborted: coderef died\n\. Rollback failed: K252::Backend->_query_async_pinned returned undef, not a Future/,
      "$fc, ROLLBACK", 1);
  }

  # -------------------------------------------------------------------------
  # deploy_async, both non-transactional branches.
  # -------------------------------------------------------------------------
  {
    local $SIG{__WARN__} = sub { };    # the (already-tested) one-shot warning
    my $backend = new_backend($fc, answer => { _execute_ddl_async => undef });
    $backend->_owner_storage(undef);   # no owner: a non-transactional engine
    fails_naming_and_releases($backend, sub { $backend->deploy_async('schema') },
      qr/_execute_ddl_async returned undef, not a Future/,
      "$fc, deploy_async on a non-transactional engine");
  }

  {
    my $backend = new_backend($fc, answer => { _run_ddl_stmts_async => undef });
    $backend->{_test_owner} = K252::LooseOwner->new;
    $backend->_owner_storage($backend->{_test_owner});
    fails_naming_and_releases($backend, sub { $backend->deploy_async('schema') },
      qr/_run_ddl_stmts_async returned undef, not a Future/,
      "$fc, deploy_async, a run outside the transaction");
  }
}

done_testing;
