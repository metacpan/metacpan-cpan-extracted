use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# Where the platform has no timer of fractions (Windows: Time::HiRes::alarm
# croaks "unimplemented in this platform") DBIO::Test::AsyncHarness::await
# still has to work: it falls back to the alarm of perl itself, in whole
# seconds rounded up, and by the clock in its own loop (there a signal reaches
# perl only now and then). Simulated here by a Time::HiRes::alarm that croaks,
# as on that platform; the file runs the same on every host.

# Whether perl's alarm reports the time left (Windows: it always answers 0).
my $ALARM_REPORTS_LEFT = do { alarm 100; my $l = alarm 0; $l > 0 };

BEGIN {
  no warnings 'redefine';
  *Time::HiRes::alarm = sub ($;$) { die "Time::HiRes::alarm(): unimplemented in this platform\n" };
}

use DBIO::Test::AsyncHarness;

{
  package T::NH::H;
  use base 'DBIO::Test::AsyncHarness';
  our $ticks = 0;
  sub _tick_loop { $ticks++; Time::HiRes::sleep(0.01) }

  package T::NH::F;
  sub new { bless { ready => $_[1], value => $_[2], after => $_[3] // 0 }, $_[0] }
  sub is_ready { my $s = shift; return $s->{ready} && $s->{after}-- <= 0 }
  sub get { $_[0]{value} }
}

ok !eval { Time::HiRes::alarm(0); 1 }, 'the stand-in: Time::HiRes::alarm croaks, as on Windows';

my $h = bless { timeout => 2 }, 'T::NH::H';

is $h->await(T::NH::F->new(1, 'v')), 'v', 'await returns a ready Future without a fractional timer';
is alarm(0), 0, '... and leaves no alarm armed';

is $h->await(T::NH::F->new(1, 'later', 3)), 'later', 'await turns the loop until the Future is ready';
is $T::NH::H::ticks, 3, '... once per not-ready answer';
is alarm(0), 0, '... and leaves no alarm armed';

my $t0 = Time::HiRes::time();
eval { $h->await(T::NH::F->new(0)) };
my $took = Time::HiRes::time() - $t0;
like $@, qr/TIMEOUT awaiting Future/, 'a Future that never resolves times out loudly';
cmp_ok $took, '>=', 1.9, '... not before the timeout';
cmp_ok $took, '<', 4, '... and not much after it';
is alarm(0), 0, '... with no alarm left armed';

{
  my $short = bless { timeout => 0.2 }, 'T::NH::H';
  my $t = Time::HiRes::time();
  eval { $short->await(T::NH::F->new(0)) };
  my $took = Time::HiRes::time() - $t;
  like $@, qr/TIMEOUT awaiting Future/, 'a fraction of a second as timeout is a timeout, never none';
  cmp_ok $took, '>=', 0.2, '... the wait lasted what was asked';
  cmp_ok $took, '<=', 1.5, '... and ends by the clock, not only by the whole-second alarm';
}

# A loop that does not let a signal through during its turn: the clock in the
# loop of await ends the wait, not the alarm.
{
  package T::NH::Deaf;
  use base 'DBIO::Test::AsyncHarness';
  our $turns = 0;
  sub _tick_loop {
    die "the wait did not end\n" if ++$turns > 600;
    local $SIG{ALRM} = 'IGNORE';
    Time::HiRes::sleep(0.01);
  }
}
{
  my $deaf = bless { timeout => 1 }, 'T::NH::Deaf';
  my $t = Time::HiRes::time();
  eval { $deaf->await(T::NH::F->new(0)) };
  my $took = Time::HiRes::time() - $t;
  like $@, qr/TIMEOUT awaiting Future in T::NH::Deaf/, 'a loop that takes no signal: the wait still ends on the timeout';
  cmp_ok $took, '>=', 0.9, '... not before it';
  cmp_ok $took, '<', 3,    '... and not much after it';
  is alarm(0), 0, '... with no alarm left armed';
}

# An alarm set by the caller is running when await is left.
SKIP: {
  skip 'perl alarm does not report the time left here; an outer alarm cannot be borrowed', 2
    unless $ALARM_REPORTS_LEFT;
  alarm 100;
  $h->await(T::NH::F->new(1, 'x', 2));
  my $left = alarm(0);
  cmp_ok $left, '>', 0,    'an outer alarm is still running after await';
  cmp_ok $left, '<=', 101, '... due about when it was due';
}

done_testing;
