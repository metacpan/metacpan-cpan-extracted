use Test::More tests => 100;

use Business::BR::RG qw /test_rg random_rg format_rg/;

for ( 1 .. 50 ) {
    my $rand_rg_nok = random_rg(0);

    is( test_rg($rand_rg_nok), 0,
        'random invalid test for ' . format_rg($rand_rg_nok) );
}

for ( 1 .. 50 ) {
    my $rand_rg_ok = random_rg(1);

    is( test_rg($rand_rg_ok), 1,
        'random valid test for ' . format_rg($rand_rg_ok) );
}
