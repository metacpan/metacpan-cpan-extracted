#!/usr/bin/perl

use Test;
BEGIN { plan tests => 3 }

package MyObject;

use Class::MakeMethods::Template::Hash (
    new             => [ 'new' ],
    'scalar'        => [ 'foo', 'bar' ]
);

package main;

my $obj;
ok( $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" ) ); #1
ok( $obj->foo() eq "Foozle" ); #2
ok( $obj->bar("Bamboozle") ); #3

