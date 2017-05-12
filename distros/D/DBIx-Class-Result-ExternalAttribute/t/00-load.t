#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Result::ExternalAttribute' ) || print "Bail out!
";
}

diag( "Testing DBIx::Class::Result::ExternalAttribute $DBIx::Class::Result::ExternalAttribute::VERSION, Perl $], $^X" );
