#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

# Oh so much cheating it isn't funny....
$^O = "WeirdIX";

my $obj = t::FancyClass->new();

ok( defined $obj, '$obj is defined' );
isa_ok( $obj, "t::FancyClass", '$obj isa t::FancyClass' );
isa_ok( $obj, "t::FancyClass::WeirdIX", '$obj isa t::FancyClass::WeirdIX' );

is( $obj->mode, "fancy", '$obj->mode' );

# More cheating
$^O = "BoringOS";

$obj = t::FancyClass->new();

ok( defined $obj, '$obj is defined' );
isa_ok( $obj, "t::FancyClass", '$obj isa t::FancyClass' );

is( $obj->mode, "boring", '$obj->mode' );

package t::FancyClass;

use Class::ByOS;

sub __new
{
   my $class = shift;
   return bless {}, $class;
}

sub mode { "boring" }

package t::FancyClass::WeirdIX;

use base qw( t::FancyClass );

sub mode { "fancy" }

1;
