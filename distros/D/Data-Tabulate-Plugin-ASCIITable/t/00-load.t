#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Tabulate::Plugin::ASCIITable' );
}

diag( "Testing Data::Tabulate::Plugin::ASCIITable $Data::Tabulate::Plugin::ASCIITable::VERSION, Perl $], $^X" );
