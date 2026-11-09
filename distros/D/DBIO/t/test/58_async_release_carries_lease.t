use strict;
use warnings;
use Test::More;
use Scalar::Util ();

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k275. A release that arrives after its connection went on is told from
# its holder's by the lease of the borrow (t/storage/pool_double_release.t).
# That only helps where the callers pass it. Core's own callers that borrow a
# pooled connection and hand it back -- txn_do_async, pipeline and
# deploy_async -- take the lease right after the acquire and release with it.
#
# The fixture: a real PoolBase of size 1 that logs, for every release, the
# lease it was given next to the connection's current one. The claim: a lease
# was passed, and it is the borrow's own -- so the release is taken, and the
# connection is idle again.
# Run against DBIO::Test::Future and, where installed, Future.pm.

{
  package K275::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K275::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection   { K275::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { }

  sub release {
    my ($self, $conn, @rest) = @_;
    push @{ $self->{release_log} }, {
      args    => scalar(@rest),
      lease   => $rest[0],
      current => $self->{_leases}{ Scalar::Util::refaddr($conn) },
    };
    return $self->SUPER::release($conn, @rest);
  }
}

{
  package K275::DdlOwner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package K275::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]->{fc} }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _install_ddl     { $_[0]->{ddl} }
  # A transport with a session reset (karr core k398): the released
  # connection is idle again once it answered.
  sub _reset_pool_connection { $_[0]->future_class->new->done }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K275::Pool->new(
      storage      => $self,
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
      on_error     => sub { warn "pool error: $_[0]\n" },
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my ($verb) = $sql =~ /^(\w+)/;
    return $self->future_class->new->done($verb eq 'SELECT' ? 'row' : ());
  }

  sub _pipeline_enter { $_[1]->{in_pipeline} = 1; return 1 }
  sub _pipeline_sync  { $_[0]->future_class->new->done }
  sub _pipeline_exit  { $_[1]->{in_pipeline} = 0; return 1 }
}

my @warnings;
local $SIG{__WARN__} = sub {
  return if $_[0] =~ /^non-transactional DDL on K275::Backend /;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, %wire) = @_;
  my $owner = delete $wire{owner};

  my ($schema, $backend);
  if ($owner) {
    $backend = K275::Backend->new(undef);
    $backend->{_test_owner} = $owner;
  }
  else {
    $schema  = DBIO::Test->init_schema;
    $backend = K275::Backend->new($schema);
    $owner   = $schema->storage;
    $backend->{_test_schema_guard} = $schema;
  }
  $backend->{fc} = $fc;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token)
    if $owner->can('_async_context_owner_token');
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

sub released_with_its_lease {
  my ($l, $backend, $f) = @_;
  my $pool = $backend->pool;

  ok $f->is_ready && !$f->is_failed, "$l: the work finished" or diag $f->failure;
  is scalar @{ $pool->{release_log} || [] }, 1, "$l: the connection was released once";
  my $rel = $pool->{release_log}[0] || {};
  is $rel->{args}, 1, "$l: ... with a lease";
  ok defined $rel->{lease}, "$l: ... a defined one";
  is $rel->{lease}, $rel->{current}, "$l: ... the one of the borrow it ended";
  is $pool->available, 1, "$l: the release was taken: the connection is idle";
  is_deeply [ splice @warnings ], [], "$l: nothing warned";
}

my @future_classes = ('DBIO::Test::Future');
push @future_classes, 'Future' if eval { require Future; 1 };

for my $fc (@future_classes) {
  {
    my $l = "$fc, txn_do_async";
    my $backend = new_backend($fc);
    my $f = $backend->txn_do_async(sub {
      return $_[0]->_query_async('SELECT 1', []);
    });
    released_with_its_lease($l, $backend, $f);
  }

  {
    my $l = "$fc, pipeline";
    my $backend = new_backend($fc);
    my $f = $backend->pipeline(sub { return $_[0]->_query_async('SELECT 1', []) });
    released_with_its_lease($l, $backend, $f);
  }

  {
    my $l = "$fc, deploy_async on a non-transactional engine";
    my $backend = new_backend($fc,
      owner => K275::DdlOwner->new(0),
      ddl   => 'CREATE TABLE a (id int);',
    );
    my $f = $backend->deploy_async('schema');
    released_with_its_lease($l, $backend, $f);
  }
}

done_testing;
