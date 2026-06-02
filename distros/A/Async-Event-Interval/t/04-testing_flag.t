use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable qw(SEM_TESTING);
use String::CRC32;
use Test::More;

use Async::Event::Interval;

my $DIST          = $TestHelper::TESTING_DIST;
my $expected_hash = (String::CRC32::crc32($DIST) & 0x7FFF) || 1;

# 1. AEI's %events parent segment is tagged.
{
    my $register = IPC::Shareable::global_register();
    my ($events_id) = grep {
        my $k = $register->{$_};
        defined $k && $k->attributes('protected')
            && $k->attributes('protected') == Async::Event::Interval::_shm_lock()
    } keys %$register;

    ok defined $events_id, "Located AEI %events knot in global_register";

    my $knot = $register->{$events_id};
    my $stat = $knot->sem->stat;

    is $stat->nsems, 5,
        "AEI %events semaphore set has 5 slots (testing-tagged)";
    is $knot->sem->getval(SEM_TESTING), $expected_hash,
        "AEI %events SEM_TESTING holds crc32('$DIST')";
}

# 2. shared_scalar() segments inherit the tag.
{
    my $e = Async::Event::Interval->new(0, sub {});
    my $s = $e->shared_scalar;
    my $knot = tied $$s;

    is $knot->sem->stat->nsems, 5,
        "shared_scalar() segment has 5-slot semaphore";
    is $knot->sem->getval(SEM_TESTING), $expected_hash,
        "shared_scalar() segment is testing-tagged";
}

# 3. An ad-hoc tie in test code inherits the tag.
{
    tie my %h, 'IPC::Shareable', {
        key     => 'AEI_TF3',
        create  => 1,
        destroy => 1,
    };

    my $knot = tied %h;

    is $knot->sem->stat->nsems, 5,
        "Ad-hoc tie in a TestHelper test auto-tags via testing_set()";
    is $knot->sem->getval(SEM_TESTING), $expected_hash,
        "...with the correct hash";
}

# 4. clean_up_testing() removes orphans not in %global_register.
{
    {
        tie my %orphan, 'IPC::Shareable', {
            key     => 'AEI_TF4',
            create  => 1,
            destroy => 0,
        };
    }

    my $removed = IPC::Shareable::clean_up_testing($DIST);
    cmp_ok $removed, '>=', 1,
        "clean_up_testing() found and removed the orphan";
}
