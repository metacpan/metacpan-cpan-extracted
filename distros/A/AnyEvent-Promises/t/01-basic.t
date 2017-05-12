use strict;
use warnings;

use Test::More;
use t::Utils;

BEGIN { use_ok( 'AnyEvent::Promises', 'deferred' ) }

my $d = deferred();
can_ok( $d, 'resolve', 'reject', 'promise' );

my $p = $d->promise;
can_ok( $p, 'then', 'value', 'values', 'reason', 'is_fulfilled',
    'is_rejected', 'is_pending' );

subtest 'Promise on unresolved/unrejected deferred' => sub {
    is( $p->state, 'pending', 'state is pending' );
    ok( $p->is_pending,    'is_pending is true' );
    ok( !$p->is_fulfilled, 'is_fulfilled is false' );
    ok( !$p->is_rejected,  'is_rejected is false' );
};

$d->resolve( 'OK', 'Really' );
subtest 'Promise on resolved deferred' => sub {
    is( $p->state, 'fulfilled' );
    ok( !$p->is_pending );
    ok( $p->is_fulfilled );
    ok( !$p->is_rejected );
    is( $p->value, 'OK' );
    is_deeply( [ $p->values ], [ 'OK', 'Really' ] );
};

$d->resolve('Bad');
subtest 'Resolve after resolve is noop' => sub {
    is( $p->value, 'OK' );
    is_deeply( [ $p->values ], [ 'OK', 'Really' ] );
};

subtest 'Reject after resolve is noop' => sub {
    $d->reject('err');
    is( $p->state, 'fulfilled' );
    ok( $p->is_fulfilled );
    is_deeply( [ $p->values ], [ 'OK', 'Really' ] );
};

my $d2 = deferred();
my $p2 = $d2->promise;

$d2->reject('doomed');
subtest 'Promise on rejected' => sub {
    is( $p2->state, 'rejected' );
    ok( !$p2->is_pending );
    ok( !$p2->is_fulfilled );
    ok( $p2->is_rejected );
    is( $p2->reason, 'doomed' );
};

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

