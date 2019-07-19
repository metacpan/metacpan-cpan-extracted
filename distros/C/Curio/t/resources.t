#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest resource_method_name => sub{
    package CC::rmn;
        use Curio;
        sub foo { {5=>7} }
    package main;

    is(
        CC::rmn->factory->fetch_resource(),
        undef,
        'cannot fetch resource',
    );

    package CC::rmn;
        resource_method_name 'foo';
    package main;

    is(
        CC::rmn->factory->fetch_resource(),
        {5=>7},
        'able to fetch resource',
    );
};

subtest does_registry => sub{
    package CC::rr;
        use Curio;
        resource_method_name 'foo';
        our $RESOURCE = [2,5];
        sub foo { $RESOURCE }
    package main;

    my $curio = CC::rr->fetch();

    is(
        CC::rr->factory->find_curio( $CC::rr::RESOURCE ),
        undef,
        'resource was not registered',
    );

    package CC::rr;
        does_registry;
    package main;

    $curio = CC::rr->fetch();

    is(
        CC::rr->factory->find_curio( $CC::rr::RESOURCE ),
        $curio,
        'resource was registered',
    );
};

done_testing;
