#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

my $obj = t::StupidClass->new();

ok( defined $obj, '$obj is defined' );
isa_ok( $obj, "t::StupidClass", '$obj isa t::StupidClass' );
is( ref $obj, "t::StupidClass", '$obj isa t::StupidClass exactly' );

package t::StupidClass;

use Class::ByOS;

sub __new
{
   my $class = shift;
   return bless {}, $class;
}

1;
