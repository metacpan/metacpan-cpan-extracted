use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use File::Temp ();
use Time::HiRes ();

# OFFLINE test: the two limits on forked calls -- statement_timeout and
# max_in_flight (karr k27, part 2).
#
# WHY: a child in a slow statement writes nothing, so without a deadline the
# caller waits for the database as long as the database likes; and every call
# is a process and a connection of its own, so without a limit a burst of calls
# is a burst of logins. Both are connect options of the backend, declared to
# core through async_option_names.
#
# WHAT RUNS FOR REAL: fork + pipe, DBIO::Forked::Storage and its Future, core's
# declared-option machinery (connect_info strips and hands over the options).
# THE SUBSTITUTION: a mock sync storage whose child sleeps and notes in a file
# that it started -- the file counts the forks, because a refused call must
# not have forked.

use DBIO::Forked::Storage;
use DBIO::Forked::Future;

alarm 60;

my $started = File::Temp->new;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select {
    my ($self, $what) = @_;
    open my $fh, '>>', $started->filename or die $!;
    print {$fh} "$$\n";
    close $fh;
    if ($what eq 'sleep') { Time::HiRes::sleep(5); return ([ 'late' ]) }
    return ([ 'now' ]);
  }

  package t::Mock::Schema;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

sub forks { open my $fh, '<', $started->filename or die $!; my @l = <$fh>; scalar @l }
# A child writes its line once it runs, a moment after the fork returned: wait
# for the count to reach what is expected (5s at most), then read it.
sub forks_since {
  my ($before, $want) = @_;
  my $until = Time::HiRes::time() + 5;
  Time::HiRes::sleep(0.02) while forks() - $before < $want && Time::HiRes::time() < $until;
  return forks() - $before;
}
sub no_children_ok { is waitpid(-1, WNOHANG), -1, $_[0] }
my @schemas;   # the storage holds its schema weakly
sub backend {
  my %opts = @_;
  push @schemas, t::Mock::Schema->new(t::Mock::Storage->new);
  my $storage = DBIO::Forked::Storage->new($schemas[-1]);
  $storage->connect_info([ 'dbi:Mock:', 'u', 'p', { AutoCommit => 1, %opts } ]);
  return $storage;
}

# --- the options are declared and handed over ---------------------------------
is_deeply [ DBIO::Forked::Storage->async_option_names ],
  [ qw( statement_timeout max_in_flight ) ],
  'the backend declares statement_timeout and max_in_flight';

{
  my $s = backend(statement_timeout => 2.5, max_in_flight => 3);
  is $s->async_option('statement_timeout'), 2.5, 'statement_timeout is read back as given';
  is $s->async_option('max_in_flight'),     3,   'max_in_flight is read back as given';
  is_deeply $s->connect_info, { broker => 0, elements => 4 },
    'the connect info keeps its form only';

  $s->connect_info([ 'dbi:Mock:', 'u', 'p', {} ]);
  is $s->async_option('max_in_flight'), undef, 'a new connect_info starts from none';
}

# --- invalid values name the option and never the value -----------------------
for my $case (
  [ max_in_flight    => 0,            'a positive integer' ],
  [ max_in_flight    => 'sekret-1',   'a positive integer' ],
  [ max_in_flight    => 1.5,          'a positive integer' ],
  [ statement_timeout => 0,           'a number of seconds above 0' ],
  [ statement_timeout => -1,          'a number of seconds above 0' ],
  [ statement_timeout => 'sekret-2',  'a number of seconds above 0' ],
  [ statement_timeout => [ 1 ],       'a number of seconds above 0' ],
) {
  my ($name, $value, $takes) = @$case;
  my $err = do { local $@; eval { backend($name => $value) }; $@ };
  like $err, qr/\Q$name\E.*\Q$takes\E/, "$name: an invalid value is refused";
  unlike $err, qr/sekret|\b1\.5\b|ARRAY/, "$name: the message leaves the value out";
}

# --- statement_timeout --------------------------------------------------------
{
  my $s = backend(statement_timeout => 0.5);

  my $f = $s->select_async('sleep');
  my $t0 = Time::HiRes::time;
  my $err = do { local $@; eval { $f->get }; $@ };
  my $took = Time::HiRes::time - $t0;
  like $err, qr/statement_timeout exceeded/, 'get: a call past the deadline fails';
  unlike $err, qr/0\.5/, 'the message names the option, not the value';
  cmp_ok $took, '<', 3, "get returned long before the child would have ended ($took s)";
  ok $f->is_failed, 'the future is failed';
  no_children_ok('the child is reaped, no zombie');

  my $p = $s->select_async('sleep');
  ok !$p->is_ready, 'is_ready: pending before the deadline';
  Time::HiRes::sleep(0.7);
  ok $p->is_ready, 'is_ready: resolved once the deadline has passed';
  ok $p->is_failed, 'and failed';
  like do { local $@; eval { $p->get }; $@ }, qr/statement_timeout exceeded/, 'with the timeout message';
  no_children_ok('polling reaps the child too');

  my $q = $s->select_async('quick');
  is_deeply [ $q->get ], [ [ 'now' ] ], 'a call that answers in time is untouched';
  no_children_ok('no child left');
}

{
  my $s = backend();
  my $f = $s->select_async('sleep');
  Time::HiRes::sleep(0.7);
  ok !$f->is_ready, 'without statement_timeout nothing ends the call';
  $f->cancel;
  no_children_ok('cancelled and reaped');
}

# --- max_in_flight ------------------------------------------------------------
{
  my $s = backend(max_in_flight => 2);
  my $before = forks();

  my @f = map { $s->select_async('sleep') } 1 .. 2;
  is forks_since($before, 2), 2, 'two calls fit';

  my $err = do { local $@; eval { $s->select_async('sleep') }; $@ };
  like $err, qr/max_in_flight reached/, 'the third call is refused';
  unlike $err, qr/\b2\b/, 'the message names the option, not the value';
  Time::HiRes::sleep(0.2);
  is forks() - $before, 2, 'the refused call forked nothing';

  $f[0]->cancel;
  my $again = $s->select_async('quick');
  is forks_since($before, 3), 3, 'a cancelled call gives its slot back';
  is_deeply [ $again->get ], [ [ 'now' ] ], 'and the new call runs';

  # the slot of a resolved call is free: 'again' is resolved, so one slot is left
  my $c = $s->select_async('quick');
  ok $c, 'a resolved call gives its slot back';
  $c->get;

  undef $f[1];
  my $d = $s->select_async('sleep');
  ok $d, 'a dropped future gives its slot back';
  $d->cancel;

  eval { $_->cancel for grep { defined } @f };
  no_children_ok('no child left');
}

{
  # five calls against a limit of 2: never more than 2 children at once
  my $s = backend(max_in_flight => 2);
  my ($before, $refused, @live) = (forks(), 0);
  for (1 .. 5) {
    my $f = eval { $s->select_async('sleep') };
    if ($f) { push @live, $f } else { $refused++ }
  }
  Time::HiRes::sleep(0.2);
  is forks_since($before, 2), 2, 'five calls, limit 2: two children forked';
  is $refused, 3, 'and three calls refused';
  $_->cancel for @live;
  no_children_ok('no child left');
}

# --- a forked process counts its own ------------------------------------------
{
  my $s = backend(max_in_flight => 1);
  my $held = $s->select_async('sleep');
  my $pid = fork() // die $!;
  if (!$pid) {
    my $ok = eval { $s->select_async('quick')->get; 1 } ? 0 : 1;   # 0 = it ran
    POSIX::_exit($ok);
  }
  waitpid($pid, 0);
  is $? >> 8, 0, 'a process forked by the application counts its own calls, not its parent\'s';
  $held->cancel;
  no_children_ok('no child left');
}

done_testing;
