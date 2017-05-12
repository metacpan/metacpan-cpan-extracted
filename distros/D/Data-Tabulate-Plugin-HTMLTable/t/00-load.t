#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Tabulate::Plugin::HTMLTable' );
}

diag( "Testing Data::Tabulate::Plugin::HTMLTable $Data::Tabulate::Plugin::HTMLTable::VERSION, Perl $], $^X" );
