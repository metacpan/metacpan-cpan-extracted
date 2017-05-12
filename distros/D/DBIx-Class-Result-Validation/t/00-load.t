#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Result::Validation' ) || print "Bail out!
";
}

diag( "Testing DBIx::Class::Result::Validation $DBIx::Class::Result::Validation::VERSION, Perl $], $^X" );
