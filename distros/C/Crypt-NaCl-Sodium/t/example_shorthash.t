
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_shorthash = Crypt::NaCl::Sodium->shorthash();

# generate secret key
my $key = '1' x $crypto_shorthash->KEYBYTES;

# list of files for which we are computing the checksums
my @files = qw( t/sodium_sign.dat );

for my $file ( @files ) {
    my $mac = $crypto_shorthash->mac( $file, $key );
    is($mac->to_hex, "506340c7218a20b5", "hash");

    # which can be converted to 64-bit integer
    SKIP: {
        eval { require Math::BigInt; };
        skip "Math::BigInt not installed", 1 if $@;
        eval { require version; };
        skip "version not installed", 1 if $@;

        my $min_version = version->parse( "1.992" );
        my $v = version->parse( Math::BigInt->VERSION );

        skip "Math::BigInt older then v1.992", 1 if $v < $min_version;

        my $bi = Math::BigInt->from_hex($mac->to_hex);
        is($bi, "5792544769733959861", "mac converted to int");
    }
}

done_testing();

