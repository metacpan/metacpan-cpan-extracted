#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest resource_method_name => sub{
    package CC::rmn;
        use Curio;
        sub resource { {5=>7} }
    package main;

    isnt(
        dies{ CC::rmn->factory->fetch_resource() },
        undef,
        'cannot fetch resource',
    );

    package CC::rmn;
        resource_method_name 'resource';
    package main;

    is(
        CC::rmn->factory->fetch_resource(),
        {5=>7},
        'able to fetch resource',
    );
};

subtest registers_resources => sub{
    package CC::rr;
        use Curio;
        resource_method_name 'resource';
        our $RESOURCE = [2,5];
        sub resource { $RESOURCE }
    package main;

    my $curio = CC::rr->fetch();

    is(
        CC::rr->factory->find_curio( $CC::rr::RESOURCE ),
        undef,
        'resource was not registered',
    );

    package CC::rr;
        registers_resources;
    package main;

    $curio = CC::rr->fetch();

    is(
        CC::rr->factory->find_curio( $CC::rr::RESOURCE ),
        $curio,
        'resource was registered',
    );
};

done_testing;
