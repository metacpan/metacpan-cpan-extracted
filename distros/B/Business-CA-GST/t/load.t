#!/usr/bin/env perl

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 31;

require_ok( 'Business::CA::GST' );

my $tax = Business::CA::GST->new( buyer_region => 'ON' );
isa_ok( $tax, 'Business::CA::GST' );

cmp_ok( $tax->rate,     '==', 0.13,  "correct rate" );
cmp_ok( $tax->tax_type, 'eq', 'HST', "correct tax type" );

$tax->buyer_region( 'ee' );
dies_ok { $tax->rate } 'dies on bad region';

foreach my $region ( qw( AB BC MB NB NL NS NT ON PE SK QC YT NU) ) {
    $tax->buyer_region( $region );
    ok( $tax->rate,     "got rate for $region: " . $tax->rate );
    ok( $tax->tax_type, "got rate for $region: " . $tax->tax_type );
}

