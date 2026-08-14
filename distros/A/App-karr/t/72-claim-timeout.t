use strict;
use warnings;
use Test::More;
use Time::Piece;

use App::karr::Task;

# Ticket #63: App::karr::Role::ClaimTimeout had no direct coverage at all.
# Mutating `return $1 * 60` to `$1 * 3600` (minutes parsed as hours) and
# replacing the whole of _claim_expired with `return 0` (no claim ever expires,
# so `karr pick` can never take over a stale claim) both left the suite green --
# the role is only exercised indirectly by pick/handoff, and only through claims
# that were fresh either way.

{
  package TimeoutConsumer;
  use Moo;
  # store is the role's one requirement since ticket #144: claim_timeout_secs
  # reads $self->store->effective_config, and until then the role declared
  # nothing, so this class composed by accident rather than by contract. The
  # stub can stay empty -- every method exercised below takes its timeout as an
  # argument and never asks the board for one. t/147-claim-timeout-requires.t is
  # that one-name list's own test.
  sub store { }
  with 'App::karr::Role::ClaimTimeout';
}

my $c = TimeoutConsumer->new;

subtest '_parse_timeout' => sub {
  is( $c->_parse_timeout('1h'),  3600,  '1h' );
  is( $c->_parse_timeout('2h'),  7200,  '2h' );
  is( $c->_parse_timeout('24h'), 86400, '24h' );

  # The mutation that survived: minutes are minutes, not hours.
  is( $c->_parse_timeout('1m'),  60,    '1m is 60 seconds, not 3600' );
  is( $c->_parse_timeout('30m'), 1800,  '30m' );
  is( $c->_parse_timeout('90m'), 5400,  '90m' );

  # Anything unparseable falls back to one hour rather than to zero, which
  # would make every claim instantly stealable.
  is( $c->_parse_timeout(undef), 3600, 'undef falls back to 1h' );
  is( $c->_parse_timeout(''),    3600, 'empty string falls back to 1h' );
  is( $c->_parse_timeout('0'),   3600, 'a bare 0 falls back to 1h' );
  is( $c->_parse_timeout('7d'),  3600, 'an unsupported unit falls back to 1h' );
  is( $c->_parse_timeout('1 h'), 3600, 'a malformed value falls back to 1h' );
  is( $c->_parse_timeout('h'),   3600, 'a unit with no number falls back to 1h' );
};

sub _task_claimed_secs_ago {
  my ($secs) = @_;
  my $ts = defined $secs ? gmtime( time - $secs )->datetime . 'Z' : undef;
  return App::karr::Task->new(
    id    => 1,
    title => 'Claimed card',
    ( defined $ts ? ( claimed_by => 'agent-fox', claimed_at => $ts ) : () ),
  );
}

subtest '_claim_expired' => sub {
  # Both sides of the decision, so `return 0` and `return 1` are each fatal.
  ok( !$c->_claim_expired( _task_claimed_secs_ago(60), 3600 ),
    'a claim one minute old is still live under a 1h timeout' );
  ok( $c->_claim_expired( _task_claimed_secs_ago(7200), 3600 ),
    'a claim two hours old has expired under a 1h timeout' );

  # And that the timeout argument is actually consulted.
  ok( $c->_claim_expired( _task_claimed_secs_ago(120), 60 ),
    'the same claim expires under a 1m timeout' );
  ok( !$c->_claim_expired( _task_claimed_secs_ago(120), 86400 ),
    'and does not under a 24h timeout' );

  # An unclaimed task is not "expired": pick treats has_claimed_at as the
  # question and would otherwise double-count it.
  ok( !$c->_claim_expired( _task_claimed_secs_ago(undef), 0 ),
    'a task that was never claimed is not expired' );

  # A stamp karr did not write must not silently read as expired either.
  my $bad = App::karr::Task->new(
    id => 2, title => 'Bad stamp',
    claimed_by => 'agent-fox', claimed_at => 'not-a-timestamp',
  );
  ok( !$c->_claim_expired( $bad, 0 ), 'an unparseable claimed_at is not treated as expired' );
};

# Ticket #57. Every stamp above is karr's own shape: no fractional seconds, and
# always UTC with a trailing Z. kanban-md, the implementation karr shares boards
# with, writes Go's time.RFC3339Nano off the agent's local clock -- verified
# against the real binary as 2026-08-09T17:28:46.449764553+02:00.
#
# The old parse stripped a trailing "Z" and handed the rest to a bare
# '%Y-%m-%dT%H:%M:%S', so both the fraction and the offset were discarded and
# the stamp was read as if it were UTC. That is not a rounding error, it is the
# wrong answer in both directions: a claim stamped +02:00 read two hours younger
# than it was and never expired, one stamped -05:00 read five hours older and
# was stolen while its owner was still working.

# A stamp for a claim that is genuinely $secs old, written the way an agent
# $offset_hours away from UTC would write it, kanban-md's nanoseconds included.
sub _foreign_stamp {
  my ($secs, $offset_hours, $frac) = @_;
  $frac //= '.449764553';
  my $local = gmtime( time - $secs ) + $offset_hours * 3600;
  return $local->datetime . $frac
    . sprintf( '%s%02d:00', $offset_hours < 0 ? '-' : '+', abs $offset_hours );
}

sub _claimed_at {
  my ($stamp) = @_;
  return App::karr::Task->new(
    id => 3, title => 'Foreign stamp',
    claimed_by => 'agent-fox', claimed_at => $stamp,
  );
}

subtest '_claim_expired reads RFC3339 offsets and fractional seconds' => sub {
  # The two failures from the ticket, each the wrong way round before the fix.
  ok( $c->_claim_expired( _claimed_at( _foreign_stamp( 9000, 2 ) ), 3600 ),
    'a claim 2.5h old stamped +02:00 has expired under a 1h timeout' );
  ok( !$c->_claim_expired( _claimed_at( _foreign_stamp( 600, -5 ) ), 3600 ),
    'a claim 10m old stamped -05:00 has not' );

  # The offset has to be applied, not merely tolerated: one civil time, two
  # different instants (UTC is the civil time minus the offset), and with a 1h
  # timeout they fall on opposite sides of it.
  my $civil = gmtime( time - 1800 )->datetime;
  ok( $c->_claim_expired( _claimed_at( $civil . '+02:00' ), 3600 ),
    'that civil time at +02:00 is 2.5h ago and has expired' );
  ok( !$c->_claim_expired( _claimed_at( $civil . '-02:00' ), 3600 ),
    'and at -02:00 is 1.5h in the future, so it has not' );

  # Fractional seconds are noise against a timeout in minutes, but they must not
  # break the parse -- discarding them used to take the offset with them.
  ok( $c->_claim_expired( _claimed_at( _foreign_stamp( 7200, 0, '.123456789' ) ), 3600 ),
    'nanosecond precision does not confuse the parse' );

  # karr's own shape keeps working, with and without the Z.
  ok( $c->_claim_expired( _claimed_at( gmtime( time - 7200 )->datetime . 'Z' ), 3600 ),
    'a trailing Z is still UTC' );
  ok( $c->_claim_expired( _claimed_at( gmtime( time - 7200 )->datetime ), 3600 ),
    'and a stamp with no offset at all is read as UTC' );

  # And the offset forms that are not RFC3339 are still refused rather than
  # half-parsed into a wrong instant.
  ok( !$c->_claim_expired( _claimed_at( '2020-01-01T00:00:00+2' ), 3600 ),
    'a malformed offset is not treated as expired' );
};

subtest '_claim_expired parses without warning to STDERR' => sub {
  # Time::Piece warns "Garbage at end of string in strptime" when the format
  # does not consume the whole stamp, and the old parse never consumed the
  # offset -- so every `karr pick` next to a kanban-md agent printed two lines
  # of Time::Piece internals to stderr. eval caught the death; nothing caught
  # the warning.
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $c->_claim_expired( _claimed_at( _foreign_stamp( 9000,  2 ) ), 3600 );
    $c->_claim_expired( _claimed_at( _foreign_stamp( 600,  -5 ) ), 3600 );
    $c->_claim_expired( _claimed_at('not-a-timestamp'),            3600 );
  }
  is( scalar @warnings, 0, 'no warnings while parsing claim stamps' )
    or diag join '', @warnings;
};

done_testing;
