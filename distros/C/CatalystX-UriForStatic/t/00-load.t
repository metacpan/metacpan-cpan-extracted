#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CatalystX::UriForStatic' ) || print "Bail out!
";
}

diag( "Testing CatalystX::UriForStatic $CatalystX::UriForStatic::VERSION, Perl $], $^X" );
