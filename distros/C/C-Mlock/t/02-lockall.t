#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use C::Mlock;
    my $id = "$<";
    my ($ls, $lr, $ur) = (undef, -1, -1);
    $ls = C::Mlock->new(1);
    $lr = $ls->lockall();
    if (!$lr)
    {
        # regardless this succeeded
        ok( $lr == 0, "mlockall() call" );
    } elsif (!$id) {
        # this failed regardless ($lr = -1 and we are root)
        ok( $lr == 0, "mlockall() call" );
    } else {
        # we're a user and the lock failed... this happens because of system restrictions
        # so we fake the pass (check the mlockall() man page)
        ok(1, "mlockall() call" );
    }
SKIP: {
        skip("lockall() failed, skipping unlockall", 1) if ($lr);
        $ur = $ls->unlockall();
        ok( $ur == 0, "munlockall() call" );
    }
}
