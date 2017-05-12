#!perl

use Test::Most;
use Business::BR::Boleto::Utils qw{ mod11 };

my ( @tests, $mod );

@tests = (
    {
        input    => undef,
        expected => 1,
        name     => 'mod11( undef ) is 1',
    },
    {
        input    => '01230067896',
        expected => 1,
        name     => 'mod11( 01230067896 ) is 1',
    },
    {
        input    => '2.6153-3',
        expected => 9,
        name     => 'mod11( "2.6153-3" ) is 9',
    },
    {
        input    => '822 0000215048200974123220154098290108605940',
        expected => 1,
        name     => 'mod11 of barcode',
    },
);

foreach my $test (@tests) {
    is mod11( $test->{input} ), $test->{expected}, $test->{name};
}

## mod11 in array context
( undef, $mod ) = mod11(undef);
is $mod, 0, 'Intermediate $mod of mod11( undef ) is 0';

( undef, $mod ) = mod11('01230067896');
is $mod, 0, 'Intermediate $mod of mod11( "01230067896" ) is 0';

( undef, $mod ) = mod11('2.6153-3');
is $mod, 2, 'Intermediate $mod of mod11( "2.6153-3" ) is 2';

( undef, $mod ) = mod11('822 0000215048200974123220154098290108605940');
is $mod, 1, 'Intermediate $mod of a barcode';

done_testing;
