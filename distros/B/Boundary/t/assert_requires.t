use strict;
use warnings;
use Test::More;

use Boundary ();

subtest 'empty' => sub {
    eval {
        Boundary->assert_requires('Foo', 'IFoo');
    };
    like $@, qr/Not found interface info/;
};

subtest 'empty requires' => sub {
    local $Boundary::INFO{IFoo}{requires} = [];
    eval {
        Boundary->assert_requires('Foo', 'IFoo');
    };
    is $@, '';
};

subtest 'empty package' => sub {
    local $Boundary::INFO{IFoo}{requires} = ['hello'];
    {
        package EmptyPackage;
    }
    eval {
        Boundary->assert_requires('EmptyPackage', 'IFoo');
    };
    like $@, qr/Can't apply IFoo to EmptyPackage - missing hello/;
};

subtest 'basic' => sub {
    local $Boundary::INFO{IFoo}{requires} = ['hello'];
    {
        package Foo;
        sub hello { 'hello' }
        sub world { 'world' }
    }
    eval {
        Boundary->assert_requires('Foo', 'IFoo');
    };
    is $@, '';
};

done_testing;
