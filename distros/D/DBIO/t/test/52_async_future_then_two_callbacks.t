use strict;
use warnings;
use Test::More;
use DBIO::Exception::Server ();

use DBIO::Future::Immediate ();
use DBIO::Test::Future ();
use DBIO::Storage::Async;

# ->then($on_done, $on_fail) means the same on every Future class core ships
# (karr k284).
#
# DBIO::Future says what core calls on the class a storage names as its
# future_class, and that includes ->then with two callbacks, as Future.pm takes
# them: DBIO::Storage::Async ends a transaction, a pipeline and a deploy that
# way -- the second callback is where ROLLBACK is sent, where the connection
# goes back to the pool, where a failure gets its "BEGIN failed:" in front.
# DBIO::Future::Immediate took one callback and dropped the second. A backend
# that named it -- the mock backends of core's own tests do -- lost all of that
# on every failure: no ROLLBACK for a transaction whose coderef returned a
# failed Future, its context left active, and the connection never handed back
# on any failing road. And ->then(undef, $on_fail) on a Future that was done
# called the undef and came back failed.
#
# The claim: on a Future that is done, ->then runs its first callback; on one
# that failed, its second, with the error. What that callback returns, the
# Future it returns, or what it dies with, is the outcome. Where the callback
# for the outcome is not given, the outcome passes through unchanged. The same
# table for DBIO::Future::Immediate, DBIO::Test::Future and -- the reference
# the other two follow -- Future.pm, where installed.

my @classes = ('DBIO::Future::Immediate', 'DBIO::Test::Future');
if (eval { require Future; 1 }) { push @classes, 'Future' }
else { note 'Future.pm not installed: no reference to run the table against' }

# What a Future came to, read through the DBIO::Future contract alone.
sub outcome {
  my ($class, $f) = @_;
  return ['pending'] unless $f->is_ready;
  return [ done => $f->get ] unless $f->is_failed;
  my $error;
  my $caught = $f->catch(sub { $error = $_[0]; return $class->done });
  return [ failed => $error ];
}

my @SOURCE = (
  [ 'a Future that is done', done => 'one', 'two' ],
  [ 'a Future that failed',  fail => "the source failed\n" ],
);

# What ->then is handed: which of the two callbacks.
my @GIVEN = (
  [ 'the first callback only',  1, 0 ],
  [ 'both callbacks',           1, 1 ],
  [ 'the second callback only', 0, 1 ],
);

# What the callback that runs does, and what the Future ->then returned then
# comes to.
my @DOES = (
  [ 'returns a plain value',   sub { 'plain' },                                 [ done => 'plain' ] ],
  [ 'returns a done Future',   sub { $_[0]->done('x', 'y') },                   [ done => 'x', 'y' ] ],
  [ 'returns a failed Future', sub { $_[0]->fail("its Future failed\n") },      [ failed => "its Future failed\n" ] ],
  [ 'dies',                    sub { die "the callback died\n" },               [ failed => "the callback died\n" ] ],
);

for my $class (@classes) {
  # A Future that is settled when ->then is called, and -- where the class has
  # pending Futures at all -- one settled afterwards.
  my @when = ('settled before ->then');
  push @when, 'settled after ->then' if $class->can('new');

  for my $when (@when) {
    for my $source (@SOURCE) {
      my ($source_label, $how, @with) = @$source;
      my $failed = $how eq 'fail';

      for my $given (@GIVEN) {
        my ($given_label, $has_done, $has_fail) = @$given;
        my $runs = $failed ? ($has_fail ? 'fail' : undef) : ($has_done ? 'done' : undef);

        for my $does (@DOES) {
          my ($does_label, $body, $then_outcome) = @$does;
          my $l = "$class, $source_label ($when), ->then with $given_label"
                . ($runs ? ", which $does_label" : '');

          my @ran;
          my $on_done = $has_done ? sub { push @ran, [ done => @_ ]; $body->($class) } : undef;
          my $on_fail = $has_fail ? sub { push @ran, [ fail => @_ ]; $body->($class) } : undef;

          my ($f, $then);
          if ($when eq 'settled before ->then') {
            $f    = $class->$how(@with);
            $then = $f->then($on_done, $on_fail);
          }
          else {
            $f    = $class->new;
            $then = $f->then($on_done, $on_fail);
            is_deeply \@ran, [], "$l: no callback before the Future is settled";
            $f->$how(@with);
          }

          is_deeply \@ran, ($runs ? [ [ $runs => @with ] ] : []),
            "$l: " . ($runs ? "the callback for '$runs' runs once, with the "
                              . ($failed ? 'error' : 'values') . ', the other not'
                            : 'no callback runs');
          is_deeply outcome($class, $then),
            ($runs ? $then_outcome : [ ($failed ? 'failed' : 'done') => @with ]),
            "$l: " . ($runs ? 'and what it does is the outcome' : 'and the outcome passes through');

          # Without a callback to run the four rows are one and the same.
          last unless $runs;
        }
      }
    }
  }
}

# --- what core's second callback is for --------------------------------------
#
# txn_do_async on a backend of each class, on every road a transaction fails
# on. Whatever the class: the statements that belong on the wire went out, the
# connection was handed back once, the context has ended, the error says where
# it came from.

{
  package K284::Pool;
  sub new { bless { released => 0, fc => $_[1] }, $_[0] }
  sub acquire_txn { $_[0]->{fc}->done('CONN') }
  sub release { $_[0]->{released}++; return }
  sub shutdown { return }
}

{
  package K284::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { $_[0]->{fc} }
  sub pool { $_[0]->{pool} ||= K284::Pool->new($_[0]->{fc}) }

  sub _query_async_pinned {
    my ($self, $conn, $sql) = @_;
    push @{ $self->{sent} }, $sql;
    # The server's refusal of a COMMIT is a Server exception (ADR 0062); only
    # that makes the transaction roll back (karr k372).
    return $self->{fc}->fail($sql eq 'COMMIT'
      ? DBIO::Exception::Server->new(message => "$sql refused\n")
      : "$sql refused\n")
      if $self->{fail_on} && $sql =~ $self->{fail_on};
    return $self->{fc}->done;
  }
}

# [ the road, the statement the wire refuses, the coderef,
#   what goes out, whether the coderef ran (so there is a context), the error ]
my @TXN = (
  [ 'the transaction succeeds', undef, sub { 'kept' },
    [ 'BEGIN', 'COMMIT' ], 1, undef ],
  [ 'the coderef returns a failed Future', undef, sub { $_[0]->fail("the coderef gave up\n") },
    [ 'BEGIN', 'ROLLBACK' ], 1, qr/^the coderef gave up$/ ],
  [ 'the coderef dies', undef, sub { die "the coderef gave up\n" },
    [ 'BEGIN', 'ROLLBACK' ], 1, qr/^the coderef gave up$/ ],
  [ 'BEGIN fails', qr/^BEGIN/, sub { 'never' },
    [ 'BEGIN' ], 0, qr/^BEGIN failed: BEGIN refused$/ ],
  [ 'COMMIT fails', qr/^COMMIT/, sub { 'kept' },
    # A COMMIT the server refused ends the transaction: ROLLBACK follows (karr k372).
    [ 'BEGIN', 'COMMIT', 'ROLLBACK' ], 1, qr/^COMMIT failed: COMMIT refused$/ ],
);

for my $class (@classes) {
  for my $case (@TXN) {
    my ($road, $fail_on, $coderef, $sent, $coderef_runs, $error) = @$case;
    my $l = "$class backend, $road";

    my $backend = K284::Backend->new(undef);
    $backend->{fc}      = $class;
    $backend->{fail_on} = $fail_on;
    $backend->{sent}    = [];

    my $ctx;
    my $got = outcome($class, $backend->txn_do_async(sub { $ctx = $_[0]; $coderef->($class) }));

    if ($error) {
      is $got->[0], 'failed', "$l: txn_do_async fails";
      like $got->[1], $error, "$l: ... with the error, saying where it came from";
    }
    else {
      is_deeply $got, [ done => 'kept' ], "$l: txn_do_async resolves with the coderef's value";
    }
    is_deeply $backend->{sent}, $sent, "$l: the statements that belong on the wire went out";
    is $backend->pool->{released}, 1, "$l: the connection was handed back once";
    if ($coderef_runs) {
      ok $ctx && !$ctx->_context_active, "$l: the context has ended";
    }
    else {
      ok !$ctx, "$l: the coderef never ran";
    }
  }
}

done_testing;
