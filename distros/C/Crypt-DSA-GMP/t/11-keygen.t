#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Crypt::DSA::GMP;
use Crypt::DSA::GMP::Util qw( mod_exp );

my @sizes = (qw/512 768 1024/);
push @sizes, 2048 if $ENV{EXTENDED_TESTING};

plan tests => (4 * scalar @sizes) + 2*4;


my $dsa = Crypt::DSA::GMP->new;
foreach my $bits (@sizes) {
  diag "Generating $bits-bit key..." if $bits > 1024;
  my $key = $dsa->keygen( Size => $bits, NonBlockingKeyGeneration => 1 );
  ok($key, "Key generated, $bits bits");
  ok($key->validate, "Key passed simple validation");
  my($L, $N) = $key->sizes;
  is($L, $bits, "P is $bits bits");
  is($N, 160, "Q is 160 bits (FIPS 186-2 standard size)");
  # Note: the two consistency checks from Crypt::DSA are now performed
  # for every generated key before returning, and also before sign & verify.
}

# Proven primes
{
  my $psize = 256;
  my $qsize = 160;
  my $key = $dsa->keygen(
     Size  => $psize,
     QSize => $qsize,
     NonBlockingKeyGeneration => 1,
     Prove => 'Q' );
  ok($key, "Key generated, ($psize,$qsize) bits");
  ok($key->validate, "Key passed simple validation");
  my($L, $N) = $key->sizes;
  is($L, $psize, "P is $psize bits");
  is($N, $qsize, "Q is $qsize bits");
}
{
  my $psize = 256;
  my $qsize = 128;
  my $key = $dsa->keygen(
     Size  => $psize,
     QSize => $qsize,
     Standard => 'FIPS 186-4',
     NonBlockingKeyGeneration => 1,
     Prove => 1 );
  ok($key, "Key generated, ($psize,$qsize) bits");
  ok($key->validate, "Key passed simple validation");
  my($L, $N) = $key->sizes;
  is($L, $psize, "P is $psize bits");
  is($N, $qsize, "Q is $qsize bits");
}
