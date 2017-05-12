use strict;
use warnings;

use Test::More;
use t::Utils;

use AnyEvent::Promises qw(deferred);
use AnyEvent;

subtest then_returns_a_promise => sub {
    my $d  = deferred();
    my $p  = $d->promise;
    my $pp = $p->then( sub { } );
    can_ok( $pp, 'then', 'is_rejected', 'is_fulfilled', 'is_pending' );
    ok( $pp->is_pending );
};

subtest then_runs_in_next_tick => sub {
    my @data;

    my $pp;
    run_event_loop {
        my $cv = shift;
        my $d  = deferred();
        my $p  = $d->promise;
        $pp = $p->then( sub { push @data, 1 => [@_]; } );
        $p->then( sub { push @data, 2 => [@_] } );
        $p->then( sub { $cv->send } );
        push @data, '0';
        $d->resolve( 'one', 'two' );
        ok( $pp->is_pending,
            'promise is still pending the handler is run in next tick' );
    };

    ok( $pp->is_fulfilled );

    is_deeply( \@data, [ 0, 1, [ "one", "two" ], 2, [ "one", "two" ] ] );
};

subtest then_value => sub {

    my $d = deferred();
    $d->resolve('X');
    my $pp
        = $d->promise->then( sub { my @x = ( @_, qw(a b c) ); return @x; } );
    run_event_loop {
        my $cv = shift;
        $pp->then( sub { $cv->send } );
    };
    is_deeply( [ $pp->values ], [qw(X a b c)] );
};

subtest reject_handler => sub {

    my $d = deferred();
    $d->reject('failed');
    my $pp = $d->promise->then( undef,
        sub { my @x = ( @_, qw(a b c) ); return @x; } );
    run_event_loop {
        my $cv = shift;
        $pp->then( sub { $cv->send }, sub { $cv->send } );
    };

    ok( $pp->is_fulfilled );
    is_deeply( [ $pp->values ], [qw(failed a b c)] );
};

subtest fulfill_handler_dies => sub {
    my $d = deferred();
    my $pp = $d->promise->then( sub { die shift() . " - Oops\n" } );
    run_event_loop {
        my $cv = shift;
        $d->resolve("A");
        $pp->then( sub { $cv->send }, sub { $cv->send } );
    };

    ok( $pp->is_rejected );
    is_deeply( $pp->reason, "A - Oops\n" );
};

subtest reject_handler_dies => sub {
    my $d = deferred();
    my $pp = $d->promise->then( undef, sub { die shift() . " - Oops\n" } );
    run_event_loop {
        my $cv = shift;
        $d->reject("B");
        $pp->then( sub { $cv->send }, sub { $cv->send } );
    };

    ok( $pp->is_rejected );
    is_deeply( $pp->reason, "B - Oops\n" );
};

subtest fulfill_handler_returns_promise => sub {
    my $d  = deferred();
    my $dd = deferred();

    my @track;
    my $pp
        = $d->promise->then( sub { push @track, @_; return $dd->promise; } );
    $d->promise->then( sub { push @track, $pp->state; } );
    run_event_loop {
        my $cv = shift;
        $d->resolve("A");
        $pp->then( sub { $cv->send }, sub { $cv->send } );
        $dd->resolve('B');
    };

    ok( $pp->is_fulfilled );
    is_deeply( \@track, [ 'A', 'pending' ] );
    is( $dd->promise->value, 'B' );
    is( $pp->value,          'B' );
};

subtest reject_handler_returns_promise => sub {
    my $d  = deferred();
    my $dd = deferred();

    my @track;
    my $pp = $d->promise->then( undef,
        sub { push @track, @_; return $dd->promise; } );
    $d->promise->then( undef, sub { push @track, $pp->state; } );

    run_event_loop {
        my $cv = shift;
        $d->reject("A");
        $pp->then( sub { $cv->send }, sub { $cv->send } );
        $dd->resolve('B');
    };

    ok( $pp->is_fulfilled );
    is_deeply( \@track, [ 'A', 'pending' ] );
    is( $dd->promise->value, 'B' );
    is( $pp->value,          'B' );
};

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

