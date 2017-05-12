#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::IndexSearch::Dezi' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::IndexSearch::Dezi $DBIx::Class::IndexSearch::Dezi::VERSION, Perl $], $^X" );
