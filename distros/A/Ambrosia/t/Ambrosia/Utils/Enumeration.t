#!/usr/bin/perl
{
    package Foo;
    use strict;
    use warnings;
    use lib qw(lib t ..);

    use Ambrosia::Utils::Enumeration property => __state => RUN => 1, DONE => 2;
    use Ambrosia::Utils::Enumeration flag => __options => F1 => 0, F2 => 1, F3 => 2;

    use Ambrosia::Meta;
    class
    {
        private => [qw/__state __options/],
    };

    1;
}

{
    package main;
    use Test::More tests => 17;
    use Test::Exception;
    use lib qw(lib t ..);
    use Carp;

    use Data::Dumper;

    BEGIN {
        use_ok( 'Ambrosia::Utils::Enumeration' ); #test #1
    }

    my $foo = new Foo();

    $foo->SET_RUN;
    ok($foo->IS_RUN, 'set/get property #1');

    $foo->OFF_RUN;
    ok(!$foo->IS_RUN, 'off/get property #1');

    $foo->SET_DONE;
    ok($foo->IS_DONE, 'set/get property #2');

    $foo->OFF_DONE;
    ok(!$foo->IS_DONE, 'off/get property #2');


    $foo->ON_F1;
    ok($foo->IS_F1, 'set/get flag #2^0');
    $foo->ON_F2;
    ok($foo->IS_F2, 'set/get flag #2^1');
    $foo->ON_F3;
    ok($foo->IS_F3, 'set/get flag #2^2');

    $foo->OFF_F2;
    ok(!$foo->IS_F2, 'off/get property #2^1');
    ok($foo->IS_F1, 'set/get flag #2^0');
    ok($foo->IS_F3, 'set/get flag #2^2');

    $foo->OFF_F3;
    ok(!$foo->IS_F3, 'off/get property #2^1');
    ok($foo->IS_F1, 'set/get flag #2^0');
    ok(!$foo->IS_F2, 'set/get flag #2^1');

    $foo->OFF_F1;
    ok(!$foo->IS_F1, 'off/get property #2^1');
    ok(!$foo->IS_F1, 'set/get flag #2^0');
    ok(!$foo->IS_F2, 'set/get flag #2^1');
}

