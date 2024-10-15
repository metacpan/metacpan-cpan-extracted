#!perl
use 5.010;
use strict;
use warnings;
use Test::More import => [ qw( diag plan use_ok ) ];

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::ResultSet::PrettyPrint' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::ResultSet::PrettyPrint $DBIx::Class::ResultSet::PrettyPrint::VERSION, Perl $], $^X" );
