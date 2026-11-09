use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Future::Immediate ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# A deploy of many statements on a transport that answers at once does not
# recurse once per statement.
#
# deploy_async chains the statements of a run (_run_ddl_stmts_async) and the
# runs of a batch (_run_ddl_runs_async) through ->then. On a Future that is
# ready already, ->then runs its callback on the spot, so each statement
# opened one more level of calls on top of the one before: a deploy of a
# hundred statements or more crossed Perl's "Deep recursion" threshold, and
# the stack grew with the size of the batch.
#
# The claim: however many statements or runs a batch has, and however
# promptly the transport answers, the stack stays as deep as for one --
# no "Deep recursion" warning -- and everything the chain promised stays:
# every statement is sent, in order, never two in flight, the first failure
# ends the batch and nothing after it is sent, each run hands its connection
# back once. (t/test/51_async_deploy_nothing_left.t holds the other half: that
# nothing of the chain is left behind.)
#
# The fixture is the one of 51, with a wire that always answers at once.

{
  package K61::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K61::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K61::Conn->new(++$_[0]->{_next_id}) }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package K61::Owner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package K61::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { $_[0]->{fc} }
  sub _install_ddl { $_[0]->{ddl} }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K61::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{sent} }, $sql;
    $self->{in_flight}++;
    $self->{most_in_flight} = $self->{in_flight}
      if $self->{in_flight} > ($self->{most_in_flight} || 0);
    $self->{in_flight}--;    # answered before the caller has the Future
    return $self->future_class->fail("refused: $sql\n")
      if $self->{fail_on} && $sql =~ $self->{fail_on};
    return $self->future_class->done;
  }
}

my @warnings;
local $SIG{__WARN__} = sub {
  return if $_[0] =~ /^(?:non-transactional DDL|split DDL batch) on K61::Backend /;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, %wire) = @_;
  my $backend = K61::Backend->new(undef);
  $backend->{fc}     = $fc;
  $backend->{_owner} = K61::Owner->new(delete $wire{txn_engine});
  $backend->_owner_storage($backend->{_owner});
  $backend->{sent} = [];
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  return 'pending' unless $f->is_ready;
  return "failed: $@" unless eval { $f->get; 1 };
  return 'done';
}

my $N = 200;
my @create = map { "CREATE TABLE t$_ (id int)" } 1 .. $N;

# 150 runs: a statement that cannot be in a transaction between every two
# that can, so each ALTER is a run of its own and the CREATEs between them are
# runs as well.
my @mixed;
for my $i (1 .. 75) { push @mixed, "CREATE TABLE m$i (id int)", "ALTER TYPE mood ADD VALUE 'v$i'" }

my $wrap = sub { map { $_ =~ /^ALTER/ ? ($_) : ('BEGIN', $_, 'COMMIT') } @_ };

# [ label, transactional engine?, statements, the statement that fails,
#   what is sent on success, what is sent on failure, number of releases on success ]
my @CASES = (
  [ "$N statements, non-transactional engine", 0, \@create, $create[100],
    \@create, [ @create[0 .. 100] ], 1 ],
  [ "$N statements, one transactional run", 1, \@create, $create[100],
    [ 'BEGIN', @create, 'COMMIT' ], [ 'BEGIN', @create[0 .. 100], 'ROLLBACK' ], 1 ],
  [ '150 runs, mixed', 1, \@mixed, $mixed[100],
    [ $wrap->(@mixed) ], [ $wrap->(@mixed[0 .. 99]), 'BEGIN', $mixed[100], 'ROLLBACK' ], 150 ],
);

my @future_classes = ('DBIO::Test::Future', 'DBIO::Future::Immediate');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { note 'Future.pm not installed: run against the DBIO Futures only' }

for my $fc (@future_classes) {
  for my $case (@CASES) {
    my ($label, $txn, $ddl, $failing, $sent_ok, $sent_fail, $releases) = @$case;

    for my $ending ('succeeds', 'fails') {
      my $l = "$fc, $label, $ending";
      my $backend = new_backend($fc,
        txn_engine => $txn,
        ddl        => join(";\n", @$ddl) . ';',
        ($ending eq 'fails' ? (fail_on => qr/^\Q$failing\E$/) : ()),
      );

      my $f = $backend->deploy_async('schema');

      if ($ending eq 'succeeds') {
        is outcome($f), 'done', "$l: the deploy resolves";
        is_deeply $backend->{sent}, $sent_ok, "$l: every statement went out, in order";
        is scalar @{ $backend->pool->{release_log} }, $releases, "$l: each run handed its connection back once";
      }
      else {
        like outcome($f), qr/^failed: .*refused: \Q$failing\E/s, "$l: the deploy fails with the statement's error";
        is_deeply $backend->{sent}, $sent_fail, "$l: in order, nothing after the failure";
      }
      is $backend->{most_in_flight}, 1, "$l: one at a time, never two in flight";
      is $backend->pool->available, 1, "$l: the connection is idle in the pool";
      is_deeply [ grep { /Deep recursion/ } @warnings ], [], "$l: no deep recursion";
      is_deeply [ splice @warnings ], [], "$l: nothing warned";
    }
  }

  # The statement chain on its own, on a connection the caller holds.
  {
    my $l = "$fc, _execute_ddl_async, $N statements";
    my $backend = new_backend($fc);
    my $f = $backend->_execute_ddl_async(K61::Conn->new(7), join(";\n", @create) . ';');
    is outcome($f), 'done', "$l: resolves";
    is_deeply $backend->{sent}, \@create, "$l: in order";
    is_deeply [ splice @warnings ], [], "$l: nothing warned";
  }
}

done_testing;
