#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
use Compress::BraceExpansion;

use lib "t";
use CompressBraceExpansionTestCases;


while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    my $compress = Compress::BraceExpansion->new( { 'strings' => $test_case->{expanded} } );
    my $output = $compress->_print_tree_recurse( $test_case->{'tree'}->{'ROOT'} );

    is( $output,
        $test_case->{'tree_print'},
        $test_case->{'description'},
    );

}
