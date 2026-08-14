#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

# DBIx::Loop::Future bridges to each ecosystem's native future via the
# adapter's to_native: values and failures both cross.

use DBIx::Loop;

SKIP: {
    skip 'IO::Async required', 6 unless eval { require IO::Async::Loop; 1 };
    require DBIx::Loop::Loop::IOAsync;
    my $ad = DBIx::Loop::Loop::IOAsync->new;

    my $f  = DBIx::Loop::Future->new;
    my $nf = $ad->to_native($f);
    isa_ok($nf, 'Future', 'IOAsync to_native');
    $f->done('io-async', 42);
    is_deeply([$nf->get], ['io-async', 42], 'values cross to Future');

    my $g  = DBIx::Loop::Future->new;
    my $ng = $ad->to_native($g);
    $g->fail("io boom\n");
    ok($ng->is_failed, 'failure crosses to Future');
    like(($ng->failure)[0], qr/io boom/, 'failure text preserved');

    # IO::Async before 0.805 builds its Future by poking $f->{loop}, which a
    # Future 0.50+ is not, so $loop->new_future dies "Not a HASH reference" on
    # that pairing. The adapter falls back to a plain Future rather than take
    # the caller down with it.
    {
        # 'once': IO::Async is required at runtime, so this glob is unknown
        # to the compiler and naming it here is its only mention.
        no warnings 'redefine', 'once';
        local *IO::Async::Loop::new_future =
            sub { die "Not a HASH reference at IO/Async/Future.pm line 74.\n" };
        my $h  = DBIx::Loop::Future->new;
        my $nh = $ad->to_native($h);
        isa_ok($nh, 'Future', 'to_native past a broken $loop->new_future');
        $h->done('fallback');
        is(($nh->get)[0], 'fallback', 'values cross on the fallback future');
    }
}

SKIP: {
    skip 'Mojolicious required', 2 unless eval { require Mojo::IOLoop; 1 };
    require DBIx::Loop::Loop::Mojo;
    my $ad = DBIx::Loop::Loop::Mojo->new;

    my $f = DBIx::Loop::Future->new;
    my $p = $ad->to_native($f);
    isa_ok($p, 'Mojo::Promise', 'Mojo to_native');
    my @got;
    $p->then(sub { @got = @_ });
    $f->done('mojo', 7);
    Mojo::IOLoop->one_tick until @got;
    is_deeply(\@got, ['mojo', 7], 'values cross to Mojo::Promise');
}

SKIP: {
    skip 'AnyEvent required', 2 unless eval { require AnyEvent; 1 };
    require DBIx::Loop::Loop::AnyEvent;
    my $ad = DBIx::Loop::Loop::AnyEvent->new;

    my $f  = DBIx::Loop::Future->new;
    my $cv = $ad->to_native($f);
    $f->done('ae', 9);
    is_deeply([$cv->recv], ['ae', 9], 'values cross to a condvar');

    my $g  = DBIx::Loop::Future->new;
    my $cg = $ad->to_native($g);
    $g->fail("ae boom\n");
    my $err; eval { $cg->recv } or $err = $@;
    like($err, qr/ae boom/, 'failure crosses as condvar croak');
}

done_testing();
