use strict;
use warnings;

use Test::More;
use Test::Exception;
use AnyEvent;

use AnyEvent::Promises qw(deferred );


$SIG{ALRM} = sub {
    fail();
    diag("Some event loop was not finished");
    done_testing();
    exit();
};
alarm 15; # this is the max time of all script

for my $d ( deferred() ) {
    $d->resolve(qw(a b c));
    is_deeply(
        [ $d->promise->sync ],
        [ 'a', 'b', 'c' ],
        "sync on fulfilled promise - list context"
    );
}

for my $d ( deferred() ) {
    $d->resolve(qw(a b c));
    is(
        scalar($d->promise->sync), 
        'a',
        "sync on fulfilled promise - scalar context"
    );
}

for my $d ( deferred() ) {
    my $tm = AE::timer 1, 0, sub { $d->resolve( 4, 3, 2 ) };
    is_deeply(
        [ $d->promise->sync ],
        [ 4, 3, 2 ],
        "sync on delayed fulfilled promise"
    );
}

for my $d ( deferred() ) {
    my $tm = AE::timer 1, 0, sub { $d->resolve( 4, 3, 2 ) };
    is_deeply(
        [ $d->promise->sync ],
        [ 4, 3, 2 ],
        "sync on delayed fulfilled promise"
    );
}

for my $d ( deferred() ) {
    my $reason = "Oops, something got terribly wrong\n";
    $d->reject($reason);

    throws_ok {
        $d->promise->sync; 
    } qr{^\Q$reason}, "sync on rejected promise throws the reason";
}

for my $timeout ( undef, 2 ) {
    my $d = deferred();

    my @trace;
    my @tm = map {
        my $delay = $_;
        AE::timer $delay, 0, sub { push @trace, $delay }
    } 1, 3, 6;

    throws_ok {
        $d->promise->sync( $timeout || () );
    }
    qr{TIMEOUT\n}, "sync on pending promise (TIMEOUT)";

    if ($timeout) {
        is_deeply( \@trace, [1], "timeout can be set" );
    }
    else {
        is_deeply( \@trace, [ 1, 3 ], "default timeout is 5 seconds" );
    }
}


alarm 0;
done_testing();
exit(0);

subtest merge_all_fulfilled => sub {
    my @d = map { deferred() } 1 .. 3;
    my @p = map {$_->promise } @d;

    my @progress;
    my $merged = merge_promises(@p);
    for my $i ( 0 .. $#p){
        $p[$i]->then(sub { push @progress, $i => $merged->state });
    }
    $merged->then(sub { push @progress, [ @_ ]; });

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
    my @p = map {$_->promise } @d;

    my @progress;
    my $merged = merge_promises(@p);
    for my $i ( 0 .. $#p){
        $p[$i]->then( ( sub { push @progress, $i => $merged->state } ) x 2 );
    }
    $merged->then(undef, sub { push @progress, [ @_ ]; });

    run_event_loop {
        my $cv = shift;
        $d[0]->resolve();
        $d[2]->reject('oops');
        $d[1]->reject('another fail');
        $p[1]->then(undef, sub { $cv->send });
    };

    is_deeply( \@progress,
        [ 0 => 'pending', 2 => 'rejected', 1 => 'rejected', ['oops'], ] );
    $merged->then(sub { push @progress, [ @_ ]; });
};

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 


