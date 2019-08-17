#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

subtest default_key => sub{
    my $class = 'CC::no_keys';
    package CC::no_keys;
        use Curio;
        add_key default => (foo=>2);
        default_key 'default';
    package main;

    is(
        $class->factory->arguments(),
        { foo=>2 },
        'empty arguments',
    );
};

subtest undeclared_key => sub{
    package CC::dk;
        use Curio;
        allow_undeclared_keys;
        add_key key2 => ( foo=>'bar' );
    package main;

    is(
        CC::dk->factory->arguments('key1'),
        {},
        'empty arguments',
    );

    is(
        CC::dk->factory->arguments('key2'),
        {foo=>'bar'},
        'has arguments',
    );
};

subtest key_argument => sub{
    package CC::ka;
        use Curio;
        key_argument 'foo2';
        add_key bar2 => ( foo1=>'bar1' );
        has foo1 => ( is=>'ro' );
        has foo2 => ( is=>'ro' );
    package main;

    my $object = CC::ka->fetch('bar2');

    is( $object->foo1(), 'bar1', 'key argument was set' );
    is( $object->foo2(), 'bar2', 'key argument was set' );
};

subtest default_arguments => sub{
    package CC::da;
        use Curio;

        default_arguments (
            foo1 => 'bar1',
            foo2 => 'bar2',
        );

        add_key test => (
            foo2 => 'BAZ2',
            foo3 => 'bar3',
        );

        has foo1 => ( is=>'ro' );
        has foo2 => ( is=>'ro' );
        has foo3 => ( is=>'ro' );
    package main;

    my $object = CC::da->fetch('test');

    is( $object->foo1(), 'bar1', 'default argument was set' );
    is( $object->foo2(), 'BAZ2', 'default argument was replaced' );
    is( $object->foo3(), 'bar3', 'other argument was set' );
};

done_testing;
