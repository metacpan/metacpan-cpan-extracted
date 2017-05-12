#!perl 

use Test::More tests => 1;
use lib;
use t::Build;

BEGIN {
    use_ok( 'Data::Babel::Client' ) || print "Bail out!
";
}

diag( "Testing Data::Babel::Client $Data::Babel::Client::VERSION, Perl $], $^X" );
