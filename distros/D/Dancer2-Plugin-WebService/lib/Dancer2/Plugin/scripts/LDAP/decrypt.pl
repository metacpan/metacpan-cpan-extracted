#!/usr/bin/perl
# This utility will decrypt a string
# for usage from authorization scripts config files
#
# decrypt.pl 53616c7465645f5f15c9217ee9ccdece574abb0a242ab63d

use Crypt::CBC;
die "Syntax error. Use as decrypt.pl EncryptedSting\n" if ! exists $ARGV[0];
my  $crypt = Crypt::CBC->new(-cipher => 'Blowfish', -header => 'salt', -key => pack 'H*', '3030303149496c6c3d313169317c31615250772b45455259595553323177317c7c313231');
print $crypt->decrypt_hex($ARGV[0]);
