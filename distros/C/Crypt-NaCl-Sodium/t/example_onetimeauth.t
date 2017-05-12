
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_onetimeauth = Crypt::NaCl::Sodium->onetimeauth();

my $msg = "First message";

# generate secret key
my $key = '1' x $crypto_onetimeauth->KEYBYTES;

# calculate authenticator
my $mac = $crypto_onetimeauth->mac( $msg, $key );
is($mac->to_hex, "186893e37ba4f3b0b65271cdeeaa8afb", "mac as expected");

# verify message
ok($crypto_onetimeauth->verify($mac, $msg, $key), "msg verified");

done_testing();

