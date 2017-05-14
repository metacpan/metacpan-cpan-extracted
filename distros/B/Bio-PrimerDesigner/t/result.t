#!/usr/bin/perl

# $Id: result.t 16 2008-11-07 02:44:52Z kyclark $

#
# Tests specific to "Bio::PrimerDesigner::Result."
#

use strict;
use Test::More tests => 3;

use_ok( 'Bio::PrimerDesigner' );

my $pd     = Bio::PrimerDesigner->new;
my $result = $pd->primer3_example;

SKIP: {
    skip $pd->error, 2 if !defined $result;

    isa_ok( $result, 'Bio::PrimerDesigner::Result' );

    ok( $result->left, 'Result returns primers' ); 
}
