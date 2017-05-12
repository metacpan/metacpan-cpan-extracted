# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Crypt::CAST5') };

#########################

my $cast5 = Crypt::CAST5->new();
ok($cast5,                      "Create object");
ok($cast5->isa("Crypt::CAST5"), "...of the proper type");

# The following tests are from RFC 2144
my @tests = (
  { bits   => 128,
    key    => "0123456712345678234567893456789a",
    plain  => "0123456789abcdef",
    cipher => "238b4fe5847e44b2",
  },
  { bits   => 80,
    key    => "01234567123456782345",
    plain  => "0123456789abcdef",
    cipher => "eb6a711a2c02271b",
  },
  { bits   => 40,
    key    => "0123456712",
    plain  => "0123456789abcdef",
    cipher => "7ac816d16e9b302e",
  },
);

foreach my $test (@tests) {
  $cast5->init(pack "H*", $test->{key});
  my $enc = unpack "H*", $cast5->encrypt(pack "H*", $test->{plain});
  is($enc, $test->{cipher}, "$test->{bits}-bit encryption");
  my $dec = unpack "H*", $cast5->decrypt(pack "H*", $enc);
  is($dec, $test->{plain}, "$test->{bits}-bit decryption");
}

# end 1cast5.t
