#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'DBIx::Class::Result::ProxyField' ) || print "Bail out!";
    use_ok( 'DBIx::Class::ResultSet::ProxyField' ) || print "Bail out!";
}

diag( "Testing DBIx::Class::Result::ProxyField && DBIx::Class::ResultSet::ProxyField $DBIx::Class::Result::ProxyField::VERSION, Perl $], $^X" );
