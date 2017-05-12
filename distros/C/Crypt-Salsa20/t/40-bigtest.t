#! /usr/bin/perl
#---------------------------------------------------------------------
# 40-bigtest.t
#
# Copyright 2013 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Translation of bigtest.c from Salsa20's reference implementation
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;

use Test::More 0.88;            # done_testing

if ($ENV{AUTOMATED_TESTING}) {
  plan tests => 40970;
} else {
  diag("AUTOMATED_TESTING is not set\n".
       "Running just 1 iteration of main loop to speed up testing");
  plan tests => 4097;
}

use Crypt::Salsa20;
use Digest::MD5 ();

my $m = "\0" x 4096;
my $c = "\0" x 4096;
my $d = "\0" x 4096;
my $k = "\0" x 32;
my $v = "\0" x 8;

my $case;

my $salsa20 = Crypt::Salsa20->new(key => $k);
my $cryptor = $salsa20->cryptor;

my @expected_k = qw(
  e2d22467015c0ffb0adc5fac0ee88ccf8d467a7f07ab53d4efeac8da47fd833e
  b7716d8c7f6a5740c900442eb43b7dcc7660883691560c1b46b2bad11e20b7ce
  e2e16b83791e38c34fcb6d9fe3354e535e53ae1af3b56042804e3bbdb95f239a
  7b459ad7e6b75d26c7b91dc77fc6b77cde9213eb01ab87ac7d1b105f2b5aa092
  2a59bf554f12b710de3ce6a433084993827e3df411faf20d69021c3b673389f5
  54b5aa80f978af32c9636bc9212fa05fdd394623e068b023ec61ca708897a75c
  b2d7f0c09b88f9412929a6d97bca52d6f352cf705a037172583ecf7cc966014b
  17ceba38742d4a2ec9cd6c60294fd571165c9dedd079e00cf8e6e835112c4ec7
  af327076756ce9fa180fcbcf25e76169789db0f96f30cf693134fed7878c13ae
  6b70ec22a28817a1bc11fba8a627ef6d4d83098408188b3afe436ee66db448ca
);

for my $loop (0 .. 9) {
  my $md5 = Digest::MD5->new;

  for my $bytes (1 .. 4096) {
    if ($loop & 1) {
      $salsa20->key($k);
    } else {
      $salsa20->key(substr($k, 0, 16));
    }
    $salsa20->iv($v);
    $c = $cryptor->(substr $m, 0, $bytes);
    $md5->add($c);
    $salsa20->iv($v);
    $d = $cryptor->($c);
    ok($d eq substr($m, 0, $bytes), "loop $loop bytes $bytes")
        or diag('$d = ' . unpack('H*', $d) . "\n" .
                '$m = ' . unpack('H*', $m) . "\n");
    $case = $bytes % 3;
    if    ($case == 0) { $k ^= substr $c, 0, 32 }
    elsif ($case == 1) { $v ^= substr $c, 0, 8 }
    else { substr($m, 0, $bytes) = $c }
  }

  substr($k, 0, 16) = $md5->digest;
  is(unpack('H*', $k), $expected_k[$loop], "loop $loop");
  # This test takes a while, so we'll just run 1 iteration
  # if there's somebody waiting for it to finish.
  last unless $ENV{AUTOMATED_TESTING};
}

## This test takes far too long (it ran for 24 hours without finishing)
# my $md5 = Digest::MD5->new;
#
# for my $loop (0 .. 134217727) {
#   $c = $cryptor->($c);
#   $md5->add($c);
# }
#
# is($md5->hexdigest, '8430e54d942ea74acd0a36c239670485', "long stream");

done_testing;
