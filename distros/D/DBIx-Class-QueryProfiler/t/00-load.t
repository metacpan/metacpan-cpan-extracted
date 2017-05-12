#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::QueryProfiler' );
}

diag( "Testing DBIx::Class::QueryProfiler $DBIx::Class::QueryProfiler::VERSION, Perl $], $^X" );
