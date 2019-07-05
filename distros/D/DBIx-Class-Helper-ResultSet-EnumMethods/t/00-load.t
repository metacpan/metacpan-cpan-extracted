#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Helper::ResultSet::EnumMethods' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Helper::ResultSet::EnumMethods $DBIx::Class::Helper::ResultSet::EnumMethods::VERSION, Perl $], $^X" );
