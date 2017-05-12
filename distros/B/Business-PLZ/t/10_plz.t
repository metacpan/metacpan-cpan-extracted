use strict;
use Test::More;

use Business::PLZ;

my $p = Business::PLZ->new('12345');
is ("$p", '12345', 'new');

my @invalid = (undef, '', '123456', '12345a', '1234', { }, [ ]);
foreach my $code (@invalid) {
    eval { Business::PLZ->new( undef ) }; 
    like $@, qr{^invalid postal code}, 'invalid code';
}

my %tests = (
    53400 => 'RP', 54401 => 'RP', 53579 => 'RP', # 53400-53579 => RP
    87491 => '7'
);

while (my ($plz,$state) = each(%tests)) {
    $plz = Business::PLZ->new($plz);
    is( $plz->state, $state, "$plz : $state" );
}

my $state = Business::PLZ::iso_state('87568');
is( $state, 'AT-8', 'AT-8' );

$state = Business::PLZ::iso_state('00000');
is( $state, undef, 'non-existing PLZ' );

ok( !Business::PLZ::exists('00000'), 'non-existing PLZ');
is( Business::PLZ::iso_state('00000'), undef, 'non-existing PLZ');
is( Business::PLZ::exists('37073'), 1, 'existing PLZ');

if (0) { # skip test of all possible codes
    for my $n (0..99999) {
        $n = sprintf("%05d",$n);
        my $plz = Business::PLZ->new($n);
        my $state = $plz->iso_state;
        print "$n - $state\n" unless $state;
    }
}

done_testing;
