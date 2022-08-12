use Test2::V0;
use Test::Alien;
use Alien::Libdogecoin;

alien_ok 'Alien::Libdogecoin';
my @symbols = qw(
    dogecoin_ecc_start dogecoin_ecc_stop generatePrivPubKeypair verifyPrivPubKeypair verifyP2pkhAddress
);

ok scalar Alien::Libdogecoin->dynamic_libs, 'Dynamic libs returns true';

ffi_ok { symbols => \@symbols, api => 1 }, with_subtest {
    my $ffi = shift;

    for my $name (qw( dogecoin_ecc_start dogecoin_ecc_stop )) {
        my $func = $ffi->function( $name => [] => 'void' );
        is $func->call(), undef, "$name() returns nothing";
    }

    my $verify = $ffi->function( verifyP2pkhAddress => ['string', 'uchar'] => 'int' );
    is $verify->call( 'DFhv7MMnDBGeaNmKybvfwF3HaJxN3Dtg3y', 34 ), 1, '... and verifyP2pkhAddress should succeed';
    is $verify->call( 'DFhv7MMnDBGeaNmKybvfwF3HaJxN3D', 30 ), 0, '... or fail as appropriate';
};

done_testing;
