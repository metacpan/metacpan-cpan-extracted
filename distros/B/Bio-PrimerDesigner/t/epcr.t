#!/usr/bin/perl

# $Id: epcr.t 16 2008-11-07 02:44:52Z kyclark $

#
# Tests specific to "epcr" program.
#

use strict;
use Test::More tests => 8;

use_ok( 'Bio::PrimerDesigner' );

my $pd = Bio::PrimerDesigner->new;
isa_ok( $pd, 'Bio::PrimerDesigner' );

my $prog = $pd->program('epcr');
isa_ok( $prog, 'Bio::PrimerDesigner::epcr', 'program' );

is( $prog->binary_name, 'e-PCR', 'binary_name is "e-PCR"' );

ok( $prog->list_params, 'program returns params' );

ok( !$prog->list_aliases, 'program returns no aliases' );

ok( !$prog->verify, 'e-PCR verification fails with no args' );

ok( !$prog->run, 'run method fails with no arguments' ); 

