#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::Pulp;
use Scalar::Util();

my ($pulper);

$pulper = pulper
    if_object { $_->isa( 't::Xyzzy' ) } then { Scalar::Util::blessed $_ }
    if_type { $_ eq 'SCALAR' } then { "$$_ is a SCALAR" }
    if_value { $_ eq 'SCALAR' } then { "Type of $_ is not SCALAR" }
;

is( $pulper->pulp( \"This" ), "This is a SCALAR" );
is( $pulper->pulp( "SCALAR" ), "Type of SCALAR is not SCALAR" );

my $object = bless {}, 't::Xyzzy';
is( $pulper->pulp( $object ), "t::Xyzzy" );

package t::Xyzzy;
