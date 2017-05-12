#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;
use_ok( 'Compress::BraceExpansion' );

use lib "t";
use CompressBraceExpansionTestCases;

while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    my $compress = Compress::BraceExpansion->new( { 'strings' => $test_case->{expanded} } );

    is_deeply( $compress->_build_tree( ),
               $test_case->{'tree'},
               $test_case->{'description'},
           );


}
