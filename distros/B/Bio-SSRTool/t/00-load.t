#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::SSRTool' ) || print "Bail out!\n";
}

diag( "Testing Bio::SSRTool $Bio::SSRTool::VERSION, Perl $], $^X" );
