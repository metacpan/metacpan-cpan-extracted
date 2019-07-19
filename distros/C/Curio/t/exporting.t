#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest export_function_name => sub{
    package CC::efn;
        use Curio;
        export_function_name 'get_efn';
    package main;

    isnt( dies{ get_efn() }, undef, 'export not yet installed' );
    CC::efn->import();
    isnt( dies{ get_efn() }, undef, 'export not yet installed' );
    CC::efn->import('get_efn');
    is( dies{ get_efn() }, undef, 'export installed' );

    my $object = get_efn();
    isa_ok( $object, ['CC::efn'], 'export works' );
};

subtest always_export => sub{
    package CC::ae;
        use Curio;
        export_function_name 'get_ae';
        always_export;
    package main;

    isnt( dies{ get_ae() }, undef, 'export not yet installed' );
    CC::ae->import();
    is( dies{ get_ae() }, undef, 'export installed' );
};

subtest export_resource => sub{
    package CC::er;
        use Curio;
        export_function_name 'get_er';
        export_resource;
        sub res { 'boo' }
    package main;

    CC::er->import('get_er');
    is( get_er(), undef, 'got undef' );

    package CC::er;
        resource_method_name 'res';
    package main;

    is( get_er(), 'boo', 'got resource' );
};

subtest custom_function => sub{
    package CC::cf;
        use Curio;
        export_function_name 'get_cf';
        sub get_cf { 'blah' }
    package main;

    CC::cf->import('get_cf');
    is( get_cf(), 'blah', 'custom function retained' );
};

done_testing;
