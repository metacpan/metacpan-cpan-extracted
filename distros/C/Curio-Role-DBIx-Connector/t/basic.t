#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest initialize => sub{
    package CC::i;
        use Curio role => '::DBIx::Connector';
    package main;

    my $factory = CC::i->factory();

    is( $factory->does_caching(), 1, 'does_caching set' );
};

subtest no_keys => sub{
    package CC::nk;
        use Curio role => '::DBIx::Connector';
        add_key 'default';
        default_key 'default';
        sub dsn { 'dbi:SQLite:dbname=:memory:' }
    package main;

    my $db = CC::nk->fetch->connector();
    isa_ok( $db, ['DBIx::Connector'], 'worked' );
};

subtest does_keys => sub{
    package CC::dk;
        use Curio role => '::DBIx::Connector';
        sub dsn { 'dbi:SQLite:dbname=:memory:' }
        add_key 'writer';
    package main;

    my $db = CC::dk->fetch('writer')->connector();
    isa_ok( $db, ['DBIx::Connector'], 'worked' );
};

done_testing;
