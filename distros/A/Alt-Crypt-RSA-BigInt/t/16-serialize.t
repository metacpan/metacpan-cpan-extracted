#!/usr/bin/env perl
use strict;
use warnings;

# This test really doesn't do everything we would like.  It just verifies
# that the code isn't choking horribly -- not that it actually does its job.

use Test::More;
use Crypt::RSA::Key;

plan tests => 2;

my $keychain = new Crypt::RSA::Key; 
my ($pub, $pri) = $keychain->generate(
  Password  => "correct horse battery staple",
  Size      => 256,
);
die $keychain->errstr if $keychain->errstr();

{
  #$pub->check || die $pub->errstr();
  my $s = $pub->serialize;
  $pub->deserialize(String=>[$s]);
  #$pub->check || die $pub->errstr();
  ok($pub->check, "deserialized pub works");
}

{
  #$pri->check || die $pri->errstr();
  my $s = $pri->serialize;
  $pri->deserialize(String=>[$s]);
  #$pri->check || die $pri->errstr();
  # Crypt::RSA 1.99 will choke on this
  ok($pri->check, "deserialized pri works");
}
