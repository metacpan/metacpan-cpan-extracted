#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Crypt::RSA::Key;
use Data::Dumper;

plan tests => 1*2;

# Danaj: This is definitely not the interface I would have chosen.  It would
# seem like you'd like to be able to hand the string to generate.
# Why do I have to make a full new object to deserialize?

my $obj = new Crypt::RSA::Key;

my ($pub, $pri) = $obj->generate(
   Identity => 'Some User <someuser@example.com>',
   Password => 'guess',
   Size => 512,
   KF => 'SSH',
 );
my $n1 = $pri->n;

# You can also use IDEA, DES, DES3, Twofish2, CAST5, Rijndael, RC6, Camellia.
# Only Blowfish is required to be present based on the dependencies we list.
foreach my $cipher (qw/Blowfish/) {

  my $s = $pri->serialize( Cipher => $cipher, Password => 'serpent' );

  my ($newpub, $newpri) = $obj->generate( Size => 128, KF => 'SSH', );

  # Do it incorrectly first.  Should croak.
  eval { $newpri->deserialize( String => $s, Password => "mst" ); };
  like($@, qr/passphrase/i, "Bad passphrase will croak");

  $newpri->deserialize( String => $s, Password => "serpent" );
  # newpri should have no password assigned
  $newpri->{Password} = 'guess';
  
  is_deeply( $newpri, $pri, "private key fully deserialized using $cipher");

}
