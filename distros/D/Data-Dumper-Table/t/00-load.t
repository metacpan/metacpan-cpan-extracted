#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Dumper::Table' );
}

diag( "Testing Data::Dumper::Table $Data::Dumper::Table::VERSION, Perl $], $^X" );
