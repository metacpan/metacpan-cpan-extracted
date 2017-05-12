#!/usr/bin/perl

# $Id: result.t,v 1.4 2003/08/05 22:43:22 kclark Exp $

#
# Tests specific to "Bio::PrimerDesigner::Result."
#

use strict;
use Test::More tests => 3;

use_ok( 'Bio::PrimerDesigner' );

my $pd     = Bio::PrimerDesigner->new;
my $result = $pd->primer3_example;

SKIP: {
    skip $pd->error, 2 unless defined $result;

    isa_ok( $result, 'Bio::PrimerDesigner::Result' );

    ok( $result->left, 'Result returns primers' ); 
}
