#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Iterator::Hierarchical' );
}

ok(defined &hierarchical_iterator,'function exported');

diag( "Testing Data::Iterator::Hierarchical $Data::Iterator::Hierarchical::VERSION, Perl $], $^X" );
