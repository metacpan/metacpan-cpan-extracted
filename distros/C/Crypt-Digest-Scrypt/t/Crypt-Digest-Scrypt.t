#! /usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Crypt::Digest::Scrypt', qw(scrypt_1024_1_1_256)) };

my $ltc_block_header =
{
  hash => "3a4d8e7c77a85554fc8bd30d4e42d56eb71010e769ea9737f16241ba79bed9c5",
  confirmations => 113556,
  height => 2000000,
  version => 536870912,
  versionHex => "20000000",
  merkleroot => "d5df7ed3506345ab3ca4544ea92bf21a8bf73f0bd96df5ba2ba8bace89ac2e3d",
  time => 1613205643,
  mediantime => 1613205094,
  nonce => 191081737,
  bits => "1a01a4a0",
  difficulty => 10210761.98514116,
  chainwork => "0000000000000000000000000000000000000000000005349725c267d7a2d6bb",
  nTx => 43,
  previousblockhash => "17ffe3fc57db0dbb599c15f14024074ad705d14b29ff99587474f1439decfbc4",
  nextblockhash => "a9d464f67e799f470f9cdb38168e95d87fc9ead6f7eb6aef5c23289d2b830a58",
};
my $data = pack("V", $ltc_block_header->{version}) .
    reverse(pack("H*", $ltc_block_header->{previousblockhash})) .
    reverse(pack("H*", $ltc_block_header->{merkleroot})) .
    pack("V", $ltc_block_header->{time}) .
    reverse(pack("H*", $ltc_block_header->{bits})) .
    pack("V", $ltc_block_header->{nonce});

my $hash = scrypt_1024_1_1_256($data);

is(unpack("H*", scalar reverse $hash), "00000000000000c2c6ae849d8042bd746c986461b520f4ca3391070bb19592cb", "hash matched");
