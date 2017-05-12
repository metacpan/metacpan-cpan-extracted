#!/usr/bin/env perl
use strict;
use warnings;

## 06-oaep.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::ES::OAEP;
use Crypt::RSA::Key;

plan tests => 5;

my $keysize = 1024;
my $blocksize = 86;
my $message = "My plenteous joys, Wanton in fullness, seek to hide themselves.";

# If we're not using GMP or Pari, these tests will take a *long* time.  Hence
# we're going to put up a notice right now so we are sure they see it.  My
# VirtualBox Solaris machine without GMP takes about 10 minutes to run this
# test, while on Fedora with GMP it's 0.6 seconds.
my $bigintlib = Math::BigInt->config()->{lib};
$bigintlib =~ s/^Math::BigInt:://;
diag "BigInt library: $bigintlib\n";
if ($bigintlib eq 'GMP') {
  # No further diagnostics
} elsif ($bigintlib eq 'Pari') {
  diag "GMP is much faster for this application\n";
} elsif ($bigintlib =~ /^(Fast)?Calc$/i) {
  diag "\n*** These tests will be VERY slow.  Install GMP! ***\n\n";
  $keysize   = 640;   # 768
  $blocksize =  38;   #  54
  $message = "My message, wanton in its brevity";
} else {
  diag "Unknown library.  Consider installing GMP for performance.\n";
}

my $oaep = new Crypt::RSA::ES::OAEP;
my $keychain = new Crypt::RSA::Key;

my ($pub, $priv) = $keychain->generate (
  Size => $keysize,
  Password => 'xx',
  Identity => 'xx',
  Verbosity => 1 );
ok( ! $keychain->errstr, "No error from generate" );

is( $oaep->encryptblock(Key => $pub), $blocksize, "encryptblock" );

my $ct = $oaep->encrypt (Key => $pub, Message => $message);
ok( ! $oaep->errstr, "No error from oaep encrypt" );
my $pt = $oaep->decrypt (Key => $priv, Cyphertext => $ct);
ok( ! $oaep->errstr, "No error from oaep decrypt" );

is( $pt, $message, "round trip message->encrypt->decrypt = message" );
diag("pt: $pt") if $pt ne $message;
