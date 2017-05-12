#!/usr/bin/perl
# This utility will encrypt a string
# for usage from authorization scripts config files
#
# encrypt.pl "Hello world"

use Crypt::CBC;
die "Syntax error. Use as encrypt.pl EncryptMe\n" if ! exists $ARGV[0];
my  $crypt = Crypt::CBC->new(-cipher => 'Blowfish', -header => 'salt', -key => pack 'H*', '3030303149496c6c3d313169317c31615250772b45455259595553323177317c7c313231');
print $crypt->encrypt_hex($ARGV[0]);
$crypt->finish()