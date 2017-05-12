use strict;
use warnings;

use Test::More;
use t::Utils;

BEGIN {
    use_ok( 'AnyEvent::Promises', 'merge_promises', 'deferred' );
}

subtest merge_all_fulfilled => sub {
    my @d = map { deferred() } 1 .. 3;
    my @p = map { $_->promise } @d;

    my @progress;
    my $merged = merge_promises(@p);
    for my $i ( 0 .. $#p ) {
        $p[$i]->then( sub { push @progress, $i => $merged->state } );
    }
    $merged->then( sub { push @progress, [@_]; } );

    run_event_loop {
        my $cv = shift;
        $d[0]->resolve( 'd0', 'dd0' );
        $d[2]->resolve('d2');
        $d[1]->resolve('d1');
        $merged->then( ( sub { $cv->send } ) x 2 );
    };

    is_deeply(
        \@progress,
        [   0 => 'pending',
            2 => 'pending',
            1 => 'fulfilled',
            [ 'd0', 'd1', 'd2' ]
        ]
    );
};

subtest merge_some_rejected => sub {
    my @d = map { deferred() } 1 .. 3;
    my @p = map { $_->promise } @d;

    my @progress;
    my $merged = merge_promises(@p);
    for my $i ( 0 .. $#p ) {
        $p[$i]->then( ( sub { push @progress, $i => $merged->state } ) x 2 );
    }
    $merged->then( undef, sub { push @progress, [@_]; } );

    run_event_loop {
        my $cv = shift;
        $d[0]->resolve();
        $d[2]->reject('oops');
        $d[1]->reject('another fail');
        $p[1]->then( undef, sub { $cv->send } );
    };

    is_deeply( \@progress,
        [ 0 => 'pending', 2 => 'rejected', 1 => 'rejected', ['oops'], ] );
    $merged->then( sub { push @progress, [@_]; } );
};

subtest merge_empty => sub {
    my $values;
    run_event_loop {
        my $cv = shift;
        merge_promises()->then(sub { $values = [@_]; $cv->send});
    };
    is_deeply($values, [], 'merge_promises() returns resolved promise');
};

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:
