#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest no_keys => sub{
    package CC::nk;
        use Curio;
    package main;

    my $regular = CC::nk->fetch();
    my $custom = CC::nk->new();

    is( CC::nk->fetch(), $regular, 'fetch returned regular object' );
    CC::nk->inject( $custom );
    is( CC::nk->fetch(), $custom, 'fetch returned custom object' );
    CC::nk->uninject();
    is( CC::nk->fetch(), $regular, 'fetch returned regular object' );
};

subtest keys => sub{
    package CC::k;
        use Curio;
        add_key 'foo';
    package main;

    my $regular = CC::k->fetch('foo');
    my $custom = CC::k->new();

    is( CC::k->fetch('foo'), $regular, 'fetch returned regular object' );
    CC::k->inject( 'foo', $custom );
    is( CC::k->fetch('foo'), $custom, 'fetch returned custom object' );
    CC::k->uninject('foo');
    is( CC::k->fetch('foo'), $regular, 'fetch returned regular object' );
};

done_testing;
