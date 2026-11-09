package GuardedWait;

# The one place a test of this distribution puts a timeout of its own on a
# wait (karr k88).
#
# A process has ONE alarm. Nine live files each carried a copy of
#
#   sub await_guarded {
#     my ($f, $what) = @_;
#     local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
#     alarm 15;
#     EV::run(EV::RUN_ONCE) until $f->is_ready;
#     alarm 0;
#     return $f;
#   }
#
# and `alarm 0` clears whatever alarm was running. So none of them could guard
# itself as a whole with `alarm 120;` -- the first wait would have taken that
# off the clock -- and what they did outside such a wait was guarded by
# nothing; a wait inside another took that one's timeout; a die out of the
# wait left this one's alarm running, to fire later under no handler.
#
# Here the alarm is borrowed: one that is running when a wait starts is
# running when it ends, on every way out, due when it was due; one that is due
# before the wait's timeout fires at its own time as itself. That is what
# DBIO::Test::AsyncHarness::await does since core's k300, and this is that
# await -- no alarm is set, cleared or handled in this file. Core's wait is
# written for a harness with a schema behind it; it asks its harness for two
# things only, timeout and _tick_loop, and its Future for is_ready and get, so
# the wait below answers all four and is its own harness and its own Future.
# What is added here is what the live files need and core's await does not
# do: the Future comes back whether it is done or failed (they assert on a
# failed one), the timeout dies with the caller's message, and an error out
# of the wait is the error as it was thrown.
#
# t/79-guarded-wait.t holds the behaviour; t/80-alarm-one-place.t keeps a
# second alarm, a handler and `alarm 0` out of the test files.
#
# Not part of the installed DBIO::PostgreSQL::EV::TestHarness: that one is
# public interface, and its await is core's as it is.

use strict;
use warnings;

use Carp ();
use EV ();

use base 'DBIO::Test::AsyncHarness';

# Run the EV loop until $f is ready and return $f -- done or failed, that is
# the caller's to look at. After $seconds it dies with $message instead, as
# it is given.
sub until_ready {
  my ($class, $f, $seconds, $message) = @_;
  $class->_guarded($seconds, $message, sub { EV::run(EV::RUN_ONCE()) }, sub { $f->is_ready });
  return $f;
}

# Call $code, which blocks, under the same guard: for what hands out no
# Future to wait for. Returns nothing; a die out of $code is passed on as it
# is.
sub run {
  my ($class, $code, $seconds, $message) = @_;
  my $ran;
  $class->_guarded($seconds, $message, sub { $code->(); $ran = 1 }, sub { $ran });
  return;
}

sub _guarded {
  my ($class, $seconds, $message, $turn, $ready) = @_;
  # core's await takes a false timeout for "no timeout": the unguarded wait
  Carp::croak('GuardedWait: a wait needs a timeout in seconds')
    unless defined $seconds && $seconds > 0;
  my $wait = bless { seconds => $seconds, turn => $turn, ready => $ready }, $class;
  return if eval { $wait->await($wait); 1 };
  my $error = exists $wait->{died} ? $wait->{died} : $@;
  die $message if !ref $error && $error =~ /\ATIMEOUT awaiting Future in \Q$class\E\n/;
  die $error;
}

# What core's await asks of its harness ...
sub timeout    { return $_[0]{seconds} }
sub _tick_loop { return $_[0]->_as_it_died('turn') }

# ... and of its Future.
sub is_ready { return $_[0]->_as_it_died('ready') }
sub get      { return }

# core's await passes an error on with croak, which writes the caller's file
# and line behind it -- behind a message that ends in a newline as well. A
# test compares the error of what it called word for word, so the error is
# kept here as it was thrown, and _guarded dies with that.
sub _as_it_died {
  my ($self, $what) = @_;
  my $answer;
  return $answer if eval { $answer = $self->{$what}->(); 1 };
  $self->{died} = $@;
  die $self->{died};
}

1;
