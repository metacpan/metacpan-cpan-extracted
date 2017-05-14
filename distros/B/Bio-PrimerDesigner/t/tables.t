#!/usr/bin/perl

# $Id: tables.t 16 2008-11-07 02:44:52Z kyclark $

#
# Tests specific to "Bio::PrimerDesigner::Tables."
#
use strict;

use Test::More tests => 10;
use Bio::PrimerDesigner;
use Data::Dumper;

use_ok( 'Bio::PrimerDesigner::Tables' );

my $t = Bio::PrimerDesigner::Tables->new;
isa_ok( $t, 'Bio::PrimerDesigner::Tables' );

my $pd   = Bio::PrimerDesigner->new;
my $pcr  = $pd->primer3_example;

SKIP: {
    skip $pd->error, 8 unless defined $pcr;

    #my $epcr = $pd->epcr_example;

    ok( $t->info_table( 'foo', bar => 'baz' ), 'info_table returns something' );

    ok( $t->PCR_header, 'PCR_header returns something' );

    ok( $t->PCR_set, 'PCR_set returns something' );

    ok( $t->PCR_row( primers => $pcr ), 'PCR_row returns something' ); 

    ok( !$t->PCR_row, 'PCR_row fails with no arguments' );


    #
    # still needs work  -- works locally but remote CGI fails 
    #
    #ok( $t->ePCR_row( $epcr ), 'ePCR_row returns something' );

    ok( !$t->ePCR_row, 'ePCR_row fails with no arguments' );

    ok( $t->render(foo=>'bar'), 'render returns something' );

    ok( $t->PCR_map, 'PCR_map returns something' );
}
