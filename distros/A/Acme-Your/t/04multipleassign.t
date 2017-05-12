#!perl
use warnings;
use strict;

use Test::More tests => 8;
use Acme::Your 'Foo';

package Foo;
use vars qw( $foo $bar );

$foo = 'foo';
$bar = 'bar';

package main;

is( $Foo::foo, 'foo', "remote start foo" );
is( $Foo::bar, 'bar', "remote start bar" );

{
    your ($foo, $bar) = qw( baz quux );
    is( $foo, 'baz', "inner local foo" );
    is( $bar, 'quux', "inner local bar" );
    is( $Foo::foo, 'baz', "inner remote foo" );
    is( $Foo::bar, 'quux', "inner remote bar" );
}

is( $Foo::foo, 'foo', "remote end foo" );
is( $Foo::bar, 'bar', "remote end bar" );
