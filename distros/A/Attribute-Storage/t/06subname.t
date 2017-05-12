#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Attribute::Storage qw( get_subattr );

sub Foo :ATTR(CODE,NAME)
{
   my ( $package, $subname, @values ) = @_;

   return {
      package => $package,
      subname => $subname,
      values  => \@values,
   };
}

sub myfunc :Foo("red","blue") { }

is_deeply( get_subattr( \&myfunc, "Foo" ),
   { package => "main", subname => "myfunc", values => [ "red", "blue" ] },
   'sub name visible for :ATTR(NAME)' );

is_deeply( get_subattr( sub :Foo("green") { }, "Foo" ),
   { package => "main", subname => "__ANON__", values => [ "green" ] },
   'sub name for :ATTR(NAME) on anonymous function' );

done_testing;
