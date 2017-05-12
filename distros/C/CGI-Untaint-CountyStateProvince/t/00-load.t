#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Untaint::CountyStateProvince' ) || print "Bail out!
";
}

diag( "Testing CGI::Untaint::CountyStateProvince $CGI::Untaint::CountyStateProvince::VERSION, Perl $], $^X" );
