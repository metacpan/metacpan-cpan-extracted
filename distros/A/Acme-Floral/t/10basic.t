use Test::More tests => 2;

my $result = `$^X t/basic.pl`;
is( $?, 0, "$^X t/basic.pl" );
like( $result, qr/^print \$SacramentoMountainsPricklyPoppy;$/m, "Floralized" );
