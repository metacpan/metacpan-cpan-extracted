#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Auth::Extensible::Provider::Database' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Plugin::Auth::Extensible::Provider::Database $Dancer2::Plugin::Auth::Extensible::Provider::Database::VERSION, Perl $], $^X" );
