#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Dancer2::Plugin::Auth::Extensible' ) || print "Bail out!
";
}

# Tests fail with mysterious messages if this is missing, and given that it is
# a relatively new additional requirement for the tests, make sure it is
# present (GH #67)
require_ok('HTTP::BrowserDetect');

diag( "Testing Dancer2::Plugin::Auth::Extensible $Dancer2::Plugin::Auth::Extensible::VERSION, Perl $], $^X" );
