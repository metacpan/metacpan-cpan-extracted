#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

# Oh so much cheating it isn't funny....
$^O = "WeirdIX";

use t::CrazyClass;

my $obj = t::CrazyClass->new();

ok( defined $obj, '$obj is defined' );
isa_ok( $obj, "t::CrazyClass", '$obj isa t::CrazyClass' );
isa_ok( $obj, "t::CrazyClass::WeirdIX", '$obj isa t::CrazyClass::WeirdIX' );

is( $obj->mode, "crazy", '$obj->mode' );
