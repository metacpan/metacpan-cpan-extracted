use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable;
use Mock::Sub;
use Test::More;

use Async::Event::Interval;

# Sanity: the constant exists and is sensible

cmp_ok
    Async::Event::Interval::SHM_CREATE_RETRIES(),
    '>=', 1,
    "SHM_CREATE_RETRIES constant is >= 1";

is
    Async::Event::Interval::SHM_CREATE_RETRIES(),
    100,
    "SHM_CREATE_RETRIES is 100";

# 1) Bootstrap loop succeeds on the first try when keys are unique
#    (this is the default case — calling _create_events_seg() again
#    should return success without croaking).

{
    my $mock = Mock::Sub->new;
    my $rand_key = $mock->mock('Async::Event::Interval::_rand_shm_key');

    # Return a fresh, unique key per call so each tie attempt succeeds
    my $counter = 0;
    $rand_key->side_effect(sub {
        $counter++;
        return sprintf("BSTSUCCESS%02d", $counter);
    });

    my $ok = eval {
        Async::Event::Interval::_create_events_segment();
        1;
    };

    ok $ok, "_create_events_segment() returns without croaking when key is unique";
    is $rand_key->called_count, 1,
        "_create_events_segment() calls _rand_shm_key() exactly once on success";

    $rand_key->unmock;
}

# 2) Bootstrap croaks after SHM_CREATE_RETRIES failed attempts, and
#    the error message contains the count and propagates $@ from the
#    last failed tie.

{
    # Pre-occupy a known key so subsequent tie attempts with exclusive=>1
    # will collide and fail.

    my $blocker_key = 'BSTCOLLISION';

    tie my %blocker, 'IPC::Shareable', {
        key       => $blocker_key,
        create    => 1,
        exclusive => 1,
        destroy   => 1,
    };

    my $mock = Mock::Sub->new;
    my $rand_key = $mock->mock('Async::Event::Interval::_rand_shm_key');
    $rand_key->return_value($blocker_key);

    my $ok = eval {
        Async::Event::Interval::_create_events_segment();
        1;
    };

    my $err = $@;

    is $ok, undef, "_create_events_segment() croaks when every attempt collides";

    like
        $err,
        qr/Unable to create the %events shared memory segment/,
        "...croak message identifies the %events segment";

    like
        $err,
        qr/after 100 attempts/,
        "...croak message includes the retry count";

    like
        $err,
        qr/(?:exists|exclusive|Could not create)/i,
        "...croak message propagates the underlying IPC::Shareable error from \$@";

    is
        $rand_key->called_count,
        Async::Event::Interval::SHM_CREATE_RETRIES(),
        "_rand_shm_key() is called exactly SHM_CREATE_RETRIES times before croaking";

    $rand_key->unmock;
    eval { (tied %blocker)->remove };
}

# 3) The constant is the single source of truth: SHM_CREATE_RETRIES
#    controls both the loop cap and the message.

{
    # Verify that the croak message embeds the actual constant value,
    # not a hard-coded number. If the constant were ever changed to,
    # say, 50, the message would say "50" — we don't change it here
    # (that's read-only), just confirm the wiring.

    my $expected = Async::Event::Interval::SHM_CREATE_RETRIES();

    my $blocker_key = 'BSTCOLLISION2';

    tie my %blocker, 'IPC::Shareable', {
        key       => $blocker_key,
        create    => 1,
        exclusive => 1,
        destroy   => 1,
    };

    my $mock = Mock::Sub->new;
    my $rand_key = $mock->mock('Async::Event::Interval::_rand_shm_key');
    $rand_key->return_value($blocker_key);

    my $ok = eval {
        Async::Event::Interval::_create_events_segment();
        1;
    };

    like
        $@,
        qr/after \Q$expected\E attempts/,
        "croak message embeds SHM_CREATE_RETRIES, not a hard-coded literal";

    $rand_key->unmock;
    eval { (tied %blocker)->remove };
}
