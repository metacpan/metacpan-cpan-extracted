use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable qw(SEM_PROTECTED);
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

# Helper: pull the tied knot out of a SCALAR ref returned by shared_scalar()

sub knot_of {
    my $ref = shift;
    return tied $$ref;
}

# 1) shared_scalar() segments carry the protected attribute, matching
#    _shm_lock(), and the value is persisted in SEM_PROTECTED.

{
    my $e = $mod->new(0, sub {});
    my $expected_lock = $e->_shm_lock;

    my $s    = $e->shared_scalar;
    my $knot = knot_of($s);

    is
        $knot->attributes('protected'),
        $expected_lock,
        "shared_scalar() knot's 'protected' attribute equals _shm_lock()";

    is
        $knot->sem->getval(SEM_PROTECTED),
        $expected_lock,
        "shared_scalar() segment's SEM_PROTECTED equals _shm_lock()";

    cmp_ok $knot->attributes('protected'), '>',  0,
        "protected key is > 0 (0 means unprotected)";

    cmp_ok $knot->attributes('protected'), '<=', 32767,
        "protected key is within the system semaphore range";
}

# 2) IPC::Shareable->clean_up_all does NOT remove a shared_scalar
#    segment, because it's protected. This was the foot-gun before
#    the protected attribute was added.

{
    my $e = $mod->new(0, sub {});
    my $s = $e->shared_scalar;
    $$s   = "before clean_up_all";

    my $id_before = knot_of($s)->seg->id;
    my $segs_before = IPC::Shareable::seg_count();

    IPC::Shareable::clean_up_all();

    my $segs_after = IPC::Shareable::seg_count();

    is
        $segs_after,
        $segs_before,
        "clean_up_all() does not remove the protected shared_scalar segment";

    is
        $$s,
        "before clean_up_all",
        "shared_scalar value still readable after clean_up_all() (segment intact)";

    $$s = "still alive";
    is
        $$s,
        "still alive",
        "shared_scalar still writeable after clean_up_all()";
}

# 3) The owning event's DESTROY still removes the protected shared_scalar
#    segment. $knot->remove ignores the 'protected' attribute (it only
#    blocks bulk sweeps).

{
    my $segs_at_start = IPC::Shareable::seg_count();

    my ($seg_id, $sem_id);
    {
        my $e = $mod->new(0, sub {});
        my $s = $e->shared_scalar;
        $$s = 42;

        $seg_id = knot_of($s)->seg->id;
        $sem_id = knot_of($s)->sem->id;

        cmp_ok
            IPC::Shareable::seg_count(),
            '>',
            $segs_at_start,
            "creating event + shared_scalar increases seg_count";

        # event goes out of scope → DESTROY → $knot->remove on the scalar
    }

    # AEI %events parent is still alive (protected); only the shared
    # scalar (and the event's per-event child) should have been removed
    # by DESTROY.

    my $register = IPC::Shareable::global_register();
    ok
        ! exists $register->{$seg_id},
        "shared_scalar segment is gone from global_register after event DESTROY";
}

# 4) Multiple shared_scalars under the same event all share the same
#    protect key, and DESTROY cleans all of them.

{
    my $segs_at_start = IPC::Shareable::seg_count();

    my @ids;
    {
        my $e = $mod->new(0, sub {});

        my @s = map { $e->shared_scalar } 1 .. 3;

        for my $ref (@s) {
            my $knot = knot_of($ref);
            push @ids, $knot->seg->id;

            is
                $knot->attributes('protected'),
                $e->_shm_lock,
                "scalar at id=" . $knot->seg->id . " is protected with event's _shm_lock()";
        }

        cmp_ok
            scalar(@ids),
            '==',
            3,
            "three shared_scalars created";
    }

    my $register = IPC::Shareable::global_register();
    my @still_present = grep { exists $register->{$_} } @ids;

    is
        scalar(@still_present),
        0,
        "all three shared_scalar segments removed when their owning event DESTROY'd";
}
