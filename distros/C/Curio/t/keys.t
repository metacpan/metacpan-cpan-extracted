#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest 'does_keys' => sub{
    package CC::dks;
        use Curio;
    package main;

    isnt( dies{ CC::dks->fetch() }, undef, 'no key failed' );
    isnt( dies{ CC::dks->fetch('key') }, undef, 'key failed' );

    package CC::dks;
        add_key 'key';
    package main;

    isnt( dies{ CC::dks->fetch() }, undef, 'no key failed' );
    is( dies{ CC::dks->fetch('key') }, undef, 'key worked' );
};

subtest default_key => sub{
    package CC::dk;
        use Curio;
        add_key 'key';
    package main;

    isnt( dies{ CC::dk->fetch() }, undef, 'no key failed' );
    is( dies{ CC::dk->fetch('key') }, undef, 'key worked' );

    package CC::dk;
        add_key 'foo';
        default_key 'foo';
    package main;

    is( dies{ CC::dk->fetch() }, undef, 'no key worked' );
    is( dies{ CC::dk->fetch('key') }, undef, 'key worked' );
};

subtest key_argument => sub{
    package CC::ka;
        use Curio;
        add_key 'foo';
        has my_key => ( is=>'ro' );
    package main;

    my $object = CC::ka->fetch('foo');
    is( $object->my_key(), undef, 'key argument was not set' );

    package CC::ka;
        key_argument 'my_key';
    package main;

    $object = CC::ka->fetch('foo');
    is( $object->my_key(), 'foo', 'key argument was set' );
};

subtest allow_undeclared_keys => sub{
    package CC::r;
        use Curio;
        add_key 'foo';
    package main;

    is( dies{ CC::r->fetch('foo') }, undef, 'known key worked' );
    isnt( dies{ CC::r->fetch('bar') }, undef, 'unknown key failed' );

    package CC::r;
        allow_undeclared_keys;
    package main;

    is( dies{ CC::r->fetch('foo') }, undef, 'known key worked' );
    is( dies{ CC::r->fetch('bar') }, undef, 'unknown key worked' );
};

done_testing;
