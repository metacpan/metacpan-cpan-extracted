#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Dmap' ) || print "Bail out!
";
}

diag( "Testing Data::Dmap $Data::Dmap::VERSION, Perl $], $^X" );
