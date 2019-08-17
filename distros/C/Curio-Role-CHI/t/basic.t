#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest initialize => sub{
    package CC::i;
        use Curio role => '::CHI';
    package main;

    my $factory = CC::i->factory();

    is( $factory->does_caching(), 1, 'does_caching set' );
    is( $factory->cache_per_process(), 1, 'cache_per_process set' );
};

subtest no_keys => sub{
    package CC::nk;
        use Curio role => '::CHI';

        add_key 'default';
        default_key 'default';

        default_arguments (
            chi => {
                driver => 'Memory',
                global => 0,
            },
        );
    package main;

    my $chi = CC::nk->fetch->chi();
    isa_ok( $chi, ['CHI::Driver'], 'worked' );
};

subtest does_keys => sub{
    package CC::dk;
        use Curio role => '::CHI';

        add_key geo_ip => (
            chi => {
                driver => 'Memory',
                global => 0,
            },
        );
    package main;

    my $chi = CC::dk->fetch('geo_ip')->chi();
    isa_ok( $chi, ['CHI::Driver'], 'worked' );
};

done_testing;
