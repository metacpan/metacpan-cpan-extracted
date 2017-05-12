#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::Storage::DBI::OpenEdge' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::Storage::DBI::OpenEdge $DBIx::Class::Storage::DBI::OpenEdge::VERSION, Perl $], $^X" );
