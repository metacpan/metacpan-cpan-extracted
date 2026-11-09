use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# A backend that has run deploy_async is freed when its holder lets go of it.
#
# deploy_async chained the runs of a batch, and _run_ddl_stmts_async the
# statements of a run, through an anonymous sub that called itself by its own
# variable -- `my $step; $step = sub { ... ->then($step) }`. Such a sub holds
# itself, and with it everything it closes over: the backend, the connection,
# the statements not sent yet. Nothing ever broke the cycle, so every deploy --
# finished or failed -- left its backend behind for the life of the process,
# and the backend its pool with every connection in it, still open.
#
# The claim: once deploy_async's Future has settled, nothing of the deploy
# holds the backend, its pool, the connection or the statements. Dropped by
# its holder, the backend is gone -- on every road a deploy takes (a
# non-transactional engine, a transactional run, a run of statements that
# cannot run in a transaction, a batch mixing both), whether it succeeded or
# failed, whether the transport answered at once or later.
#
# And nothing else changed, which the same cases pin: the statements go out
# strictly one after the other -- never two in flight -- in the order given;
# the first failure ends the deploy and nothing after it is sent; each run
# hands its connection back to the pool once.
#
# The fixture: a real DBIO::Storage::PoolBase of size 1 logging every release;
# a fake wire that records each statement and answers it at once or when the
# test says. Against DBIO::Test::Future and, where installed, Future.pm.

{
  package K51::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K51::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K51::Conn->new(++$_[0]->{_next_id}) }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# The owner deploy_async asks: is the engine transactional, and is this
# statement. ALTER stands for the statement that cannot run in a transaction.
{
  package K51::Owner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package K51::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { $_[0]->{fc} }
  sub _install_ddl { $_[0]->{ddl} }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K51::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  # {later}: a statement is not answered until answer_next. {fail_on}: the
  # statement matching it is answered with a failure. A statement may be a
  # reference to its text, so a test can watch it being let go of.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    my $text = ref $sql ? $$sql : $sql;
    push @{ $self->{sent} }, $text;

    $self->{in_flight}++;
    $self->{most_in_flight} = $self->{in_flight}
      if $self->{in_flight} > ($self->{most_in_flight} || 0);

    my $f = $self->future_class->new;
    if ($self->{later}) { push @{ $self->{unanswered} }, [ $f, $text ] }
    else                { $self->_answer($f, $text) }
    return $f;
  }

  sub _answer {
    my ($self, $f, $text) = @_;
    $self->{in_flight}--;
    return $f->fail("refused: $text\n")
      if $self->{fail_on} && $text =~ $self->{fail_on};
    return $f->done;
  }
}

my @warnings;
local $SIG{__WARN__} = sub {
  # deploy_async's own one-shot notices.
  return if $_[0] =~ /^(?:non-transactional DDL|split DDL batch) on K51::Backend /;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, %wire) = @_;
  my $backend = K51::Backend->new(undef);
  $backend->{fc}     = $fc;
  $backend->{_owner} = K51::Owner->new(delete $wire{txn_engine});   # held weakly by the backend
  $backend->_owner_storage($backend->{_owner});
  $backend->{sent} = [];
  $backend->{$_} = $wire{$_} for keys %wire;
  return $backend;
}

# Answer what is unanswered, one statement at a time; each answer may put the
# next statement on the wire.
sub answer_all {
  my ($backend) = @_;
  while (my $next = shift @{ $backend->{unanswered} || [] }) {
    $backend->_answer(@$next);
  }
  return;
}

sub outcome {
  my ($f) = @_;
  return 'pending' unless $f->is_ready;
  return "failed: $@" unless eval { $f->get; 1 };
  return 'done';
}

my ($A, $B, $C)   = map { "CREATE TABLE $_ (id int)" } qw( a b c );
my ($X, $Y)       = map { "ALTER TYPE mood ADD VALUE '$_'" } qw( x y );

# [ label, transactional engine?, the DDL, the statement that fails in the
#   failing variant,
#   what is sent when all succeeds, releases then,
#   what is sent when that statement fails, releases then ]
my @DEPLOY = (
  [ 'a non-transactional engine', 0, [ $A, $B, $C ], $B,
    [ $A, $B, $C ], [1],
    [ $A, $B ],     [1] ],
  [ 'a transactional run', 1, [ $A, $B, $C ], $B,
    [ 'BEGIN', $A, $B, $C, 'COMMIT' ], [1],
    [ 'BEGIN', $A, $B, 'ROLLBACK' ],   [1] ],
  [ 'a run that cannot be in a transaction', 1, [ $X, $Y ], $X,
    [ $X, $Y ], [1],
    [ $X ],     [1] ],
  [ 'a batch of three runs', 1, [ $A, $X, $B ], $X,
    [ 'BEGIN', $A, 'COMMIT', $X, 'BEGIN', $B, 'COMMIT' ], [ 1, 1, 1 ],
    [ 'BEGIN', $A, 'COMMIT', $X ],                        [ 1, 1 ] ],
);

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { note 'Future.pm not installed: run against DBIO::Test::Future only' }

for my $fc (@future_classes) {
  for my $case (@DEPLOY) {
    my ($road, $txn_engine, $ddl, $failing, $sent_ok, $released_ok, $sent_fail, $released_fail) = @$case;

    for my $ending ('succeeds', 'fails') {
      for my $answered ('at once', 'later') {
        my $l = "$fc, deploy_async on $road, $ending, answered $answered";
        my %left;
        {
          my $backend = new_backend($fc,
            txn_engine => $txn_engine,
            ddl        => join(";\n", @$ddl) . ';',
            later      => ($answered eq 'later'),
            ($ending eq 'fails' ? (fail_on => qr/^\Q$failing\E$/) : ()),
          );
          my $pool = $backend->pool;

          my $f = $backend->deploy_async('schema');
          if ($answered eq 'later') {
            is outcome($f), 'pending', "$l: the deploy waits for its first answer";
            answer_all($backend);
          }

          if ($ending eq 'succeeds') {
            is outcome($f), 'done', "$l: the deploy resolves";
          }
          else {
            like outcome($f), qr/^failed: .*refused: \Q$failing\E/s,
              "$l: the deploy fails with the statement's error";
          }
          is_deeply $backend->{sent}, ($ending eq 'succeeds' ? $sent_ok : $sent_fail),
            "$l: the statements went out in order" . ($ending eq 'fails' ? ', none after the failure' : '');
          is $backend->{most_in_flight}, 1, "$l: ... one at a time, never two in flight";
          is_deeply $pool->{release_log}, ($ending eq 'succeeds' ? $released_ok : $released_fail),
            "$l: each run handed its connection back once";
          is $pool->available, 1, "$l: ... and it is idle in the pool";
          is_deeply [ splice @warnings ], [], "$l: nothing warned";

          weaken($left{backend} = $backend);
          weaken($left{pool}    = $pool);
          weaken($left{conn}    = $pool->{_connections}[0]);
          ok defined $left{conn}, "$l: (the pool has the connection the deploy ran on)";
        }
        ok !defined $left{backend}, "$l: dropped, the backend is freed";
        ok !defined $left{pool},    "$l: ... its pool with it";
        ok !defined $left{conn},    "$l: ... and the connection the deploy ran on";
      }
    }
  }

  # -------------------------------------------------------------------------
  # The statement chain on its own, as _execute_ddl_async and the seam under
  # it are called: on a connection the caller holds. Nothing of the chain
  # holds the backend or the connection afterwards.
  # -------------------------------------------------------------------------
  for my $ending ('succeeds', 'fails') {
    my $l = "$fc, _execute_ddl_async, $ending";
    my %left;
    {
      my $backend = new_backend($fc, later => 1, ($ending eq 'fails' ? (fail_on => qr/ b /) : ()));
      my $conn    = K51::Conn->new(7);

      my $f = $backend->_execute_ddl_async($conn, "$A;\n-- a comment;\n$B;\n$C;");
      answer_all($backend);
      like outcome($f), ($ending eq 'succeeds' ? qr/^done$/ : qr/^failed: .*refused: \Q$B\E/s),
        "$l: the chain ends as it should";
      is_deeply $backend->{sent}, ($ending eq 'succeeds' ? [ $A, $B, $C ] : [ $A, $B ]),
        "$l: the statements went out in order, the comment not at all";
      is $backend->{most_in_flight}, 1, "$l: ... one at a time";

      weaken($left{backend} = $backend);
      weaken($left{conn}    = $conn);
    }
    ok !defined $left{backend}, "$l: dropped, the backend is freed";
    ok !defined $left{conn},    "$l: ... and the connection";
  }

  # -------------------------------------------------------------------------
  # The statements themselves. A chain that failed never sent what came after
  # the failure; those statements are let go of with the chain, and so is the
  # list the caller handed in, which is not changed. Statements are handed in
  # as references here, so that they can be watched.
  # -------------------------------------------------------------------------
  {
    my $l = "$fc, _run_ddl_stmts_async, the first statement fails";
    my $backend = new_backend($fc, fail_on => qr/ a /);
    my $conn    = K51::Conn->new(7);

    my @statements = map { my $text = $_; \$text } $A, $B, $C;
    my @watched    = @statements;
    weaken($_) for @watched;
    my $list = [ @statements ];
    @statements = ();

    my $f = $backend->_run_ddl_stmts_async($conn, $list);
    like outcome($f), qr/^failed: .*refused: \Q$A\E/s, "$l: the chain fails";
    is_deeply $backend->{sent}, [ $A ], "$l: nothing after it was sent";
    is scalar @$list, 3, "$l: the caller's list is as it was handed in";

    undef $list;
    is_deeply [ map { defined $_ ? 'held' : 'gone' } @watched ], [ ('gone') x 3 ],
      "$l: once the caller lets go of its list, no statement is held -- sent or not";
  }

  # The chain runs what it was handed, not what the caller's list has become
  # while it ran.
  {
    my $l = "$fc, _run_ddl_stmts_async, the caller empties its list meanwhile";
    my $backend = new_backend($fc, later => 1);
    my $list    = [ $A, $B, $C ];

    my $f = $backend->_run_ddl_stmts_async(K51::Conn->new(7), $list);
    @$list = ();
    answer_all($backend);
    is outcome($f), 'done', "$l: the chain resolves";
    is_deeply $backend->{sent}, [ $A, $B, $C ], "$l: ... having sent every statement it was handed";
  }
}

done_testing;
