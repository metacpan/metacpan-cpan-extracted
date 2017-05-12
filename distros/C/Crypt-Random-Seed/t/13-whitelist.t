#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;

use Test::More  tests => 4;

# Expect croak if Only isn't an array reference
ok(!eval {Crypt::Random::Seed->new(Only=>0);}, "Only with non-array reference croaks");

SKIP: {
  my $source = Crypt::Random::Seed->new(Only=>['TESHA2']);
  if (!defined $source) {
    # Perhaps TESHA2 isn't installed.
    # That's a mis-configuration, but let's allow it.
    if (!eval { require Crypt::Random::TESHA2; 1; }) {
      diag "You don't have TESHA2 installed.";
      diag "This looks like a configuration issue.";
      diag "Proceeding since we know from earlier tests you have a source.";
      skip "Missing TESHA2", 2;
    }
  }
  ok(defined $source, "Only=>[TESHA2] returned something");
  like($source->name(), qr/^TESHA2/, "Only=>[TESHA2] returned TESHA2");
}

{
  my $source = Crypt::Random::Seed->new(Only=>[]);
  ok(!defined $source, "An empty whitelist means no object returned");
}
