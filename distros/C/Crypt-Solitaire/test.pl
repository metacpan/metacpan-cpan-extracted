#!/usr/bin/perl

use Crypt::Solitaire;

$string = "This is an encryption test.";
$passphrase = "abcdefg";
print ("Original String: $string\n");

print ("Encrypted Text: ");
$enc = Crypt::Solitaire::Pontifex( $string, $passphrase, "encrypt");
print $enc, "\n";

print ("Decrypted Text: ");
$dec = Crypt::Solitaire::Pontifex( $enc, $passphrase, "decrypt");
print $dec, "\n";
