#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Tabulate' );
}

diag( "Testing Data::Tabulate $Data::Tabulate::VERSION, Perl $], $^X" );

my $obj = Data::Tabulate->new();
isa_ok($obj,'Data::Tabulate');
