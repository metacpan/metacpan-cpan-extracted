#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::AutomatedAnnotation::Prokka');
}

my $obj ;

ok( $obj = Bio::AutomatedAnnotation::Prokka->new(
   assembly_file    => 't/data/minimal_contigs.fa',
 ), 'initialise obj with all defaults');




done_testing();