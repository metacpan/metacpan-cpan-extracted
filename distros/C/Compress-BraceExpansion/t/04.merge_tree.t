#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 26;
use Compress::BraceExpansion;

use lib "t";
use CompressBraceExpansionTestCases;

while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    my $compress = Compress::BraceExpansion->new( { 'strings' => $test_case->{expanded} } );

    my ( $junk, $tree ) = $compress->_merge_tree_recurse( $test_case->{'tree'} );
    is_deeply( $tree->{'ROOT'},
               $test_case->{'tree_merge'}->{'ROOT'},
               "root check: " . $test_case->{'description'},
           );

    my $got_pointers = $compress->_get_pointers();
    is_deeply( $got_pointers,
               $test_case->{'tree_merge'}->{'POINTERS'},
               "pointer check: " . $test_case->{'description'},
           );

}

