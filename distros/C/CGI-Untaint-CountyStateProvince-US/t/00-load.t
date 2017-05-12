#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('CGI::Untaint');
    use_ok( 'CGI::Untaint::CountyStateProvince::US' ) || print "Bail out!
";
}

diag( "Testing CGI::Untaint::CountyStateProvince::US $CGI::Untaint::CountyStateProvince::US::VERSION, Perl $], $^X" );
