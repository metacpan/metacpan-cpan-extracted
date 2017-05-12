#!/usr/bin/perl
use lib './lib';
use Crypt::Mode::CBC::Easy;

my $crypt = Crypt::Mode::CBC::Easy->new(key => "1234567892342342");

my @plaintext = qw/hello how are you doing today/;
my $ciphertext = $crypt->encrypt(@plaintext);
my @plaintext2 = $crypt->decrypt($ciphertext);

print "$ciphertext\n";
print "@plaintext2\n";

exit;

my $m = Crypt::Mode::CBC->new('Twofish');

my $key = "1234567892342342";
my $iv = "1234567890123456";
#(en|de)crypt at once
my $ciphertext = $m->encrypt($plaintext, $key, $iv);
my $plaintext2 = $m->decrypt($ciphertext, $key, $iv);

print "$ciphertext\n";
print "$plaintext2\n";
