#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest 'Moo' => sub{
    package CC::m;
        use Curio;
    package main;

    isa_ok( CC::m->new(), ['Moo::Object'], 'isa Moo::Object' );
    is( dies{ CC::m::has(foo=>(is=>'ro')) }, undef, 'Moo imported' );
    can_ok( 'CC::m', ['foo'], 'Moo works' );
};

subtest 'Curio::Declare' => sub{
    package CC::cd;
        use Curio;
    package main;

    is( dies{ CC::cd::does_caching(1) }, undef, 'Curio::Declare imported' );
    is( CC::cd->factory->does_caching(), 1, 'Curio::Declare works' );
};

subtest 'namespace::clean' => sub{
    package CC::nc;
        sub bar1 { }
        use Curio;
        sub bar2 { }
    package main;

    is( CC::nc->can('bar1'), undef, 'before sub is cleaned' );
    isnt( CC::nc->can('bar2'), undef, 'after sub is not cleaned' );
};

subtest 'Curio::Role' => sub{
    package CC::cr;
        use Curio;
    package main;

    DOES_ok( 'CC::cr', ['Curio::Role'], 'does Curio::Role' );
    can_ok( 'CC::cr', ['factory'], 'role is applied' );
};

subtest 'role' => sub{
    package Curio::Role::Test;
        use Moo::Role;
        BEGIN { with 'Curio::Role' }
        sub foo { 'bar' }
    package CC::r;
        use Curio role => '::Test';
    package main;

    is( CC::r->foo(), 'bar', 'custom role was applied' );
};

subtest 'initialize' => sub{
    package CC::sc1;
        use Moo;
        use Curio::Declare;
        use namespace::clean;
        with 'Curio::Role';
    package main;

    is( CC::sc1->factory(), undef, 'initialize was not called' );

    package CC::sc2;
        use Curio;
    package main;

    isnt( CC::sc2->factory(), undef, 'initialize was called' );
};

done_testing;
