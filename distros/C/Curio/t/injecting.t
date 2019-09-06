#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest no_keys => sub{
    package CC::nk;
        use Curio;
        allow_undeclared_keys;
        default_key 'foo';
    package main;

    my $regular = CC::nk->fetch();
    my $custom = CC::nk->new();

    is( CC::nk->injection(), undef, 'not injected' );
    is( CC::nk->fetch(), $regular, 'fetch returned regular object' );

    CC::nk->inject( foo => $custom );
    isnt( CC::nk->injection(), undef, 'is injected' );
    is( CC::nk->fetch(), $custom, 'fetch returned custom object' );

    CC::nk->clear_injection();
    is( CC::nk->injection(), undef, 'not injected' );
    is( CC::nk->fetch(), $regular, 'fetch returned regular object' );
};

subtest keys => sub{
    package CC::k;
        use Curio;
        add_key 'foo';
        has bar => (is=>'ro', default=>1);
    package main;

    my $regular = CC::k->fetch('foo');
    my $custom = CC::k->new(bar=>2);

    is( CC::k->fetch('foo'), $regular, 'fetch returned regular object' );

    CC::k->inject( 'foo', $custom );
    is( CC::k->fetch('foo'), $custom, 'fetch returned custom object' );

    CC::k->clear_injection('foo');
    is( CC::k->fetch('foo'), $regular, 'fetch returned regular object' );
};

subtest guard => sub{
    package CC::g;
        use Curio;
        allow_undeclared_keys;
        default_key 'foo';
    package main;

    my $regular = CC::g->fetch();
    my $custom = CC::g->new();

    is( CC::g->injection(), undef, 'not injected' );
    is( CC::g->fetch(), $regular, 'fetch returned regular object' );

    my $guard = CC::g->inject_with_guard( $custom );
    isnt( CC::g->injection(), undef, 'is injected' );
    is( CC::g->fetch(), $custom, 'fetch returned custom object' );

    $guard = undef;
    is( CC::g->injection(), undef, 'not injected' );
    is( CC::g->fetch(), $regular, 'fetch returned regular object' );
};

done_testing;
