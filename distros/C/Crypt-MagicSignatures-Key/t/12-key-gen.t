#!/usr/bin/env perl
use Test::More;
use Math::BigInt try => 'GMP,Pari';
use Test::Output;
use Sub::Util qw/subname/;
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

my $m = 'Math::Prime::Util 0.21';
my $mpu = eval q{use } . $m . q{ qw/random_nbit_prime/; 1;};

plan skip_all => $m . ' is not available for key generation' unless $mpu;

$m = 'Math::Prime::Util::GMP';
my $mpug = eval q{use } . $m . q{; 1;};

plan skip_all => "Test would run too slow without $m" unless $mpug;

my $module = 'Crypt::MagicSignatures::Key';
use_ok($module);   # 1

sub _b {
  return Crypt::MagicSignatures::Key::_bitsize(@_);
};

my $key;
stderr_like(
  sub {
    ok(!($key = Crypt::MagicSignatures::Key->new), 'Deprecated Key Generation');
  },
  qr/generate()/,
  'Key generation in new'
);

ok($key = Crypt::MagicSignatures::Key->generate, 'Key Generation');
ok($key->n, 'Modulus');
ok($key->e, 'Public Exponet');
ok($key->d, 'Private Exponet');

# diag 'N: ' . $key->N;
# diag 'E: ' . $key->e;
# diag 'D: ' . $key->d;

is($key->e, 65537, 'Public exponent is correct');

is(_b($key->n), 512, 'Modulus-Size is correct');

ok(my $sig = $key->sign('This is a message'), 'Signing');
ok($key->verify('This is a message', $sig), 'Verification');

stderr_like(
  sub {
    ok(!($key = Crypt::MagicSignatures::Key->new(size => 1024, e => 3)), 'Deprecated Key Generation');
  },
  qr/generate()/,
  'Generation in new with size'
);

ok($key = Crypt::MagicSignatures::Key->generate(size => 1024, e => 3), 'Key Generation');
ok($key->n, 'Modulus');
ok($key->e, 'Public Exponet');
ok($key->d, 'Private Exponet');
is($key->e, 3, 'Public exponent is correct');
is(_b($key->n), 1024, 'Modulus-Size is correct');

stderr_is(
  sub {
    ok($key = Crypt::MagicSignatures::Key->generate(size => 1024, e => 3), 'Key Generation');
  },
  '',
  'No error'
);

$Crypt::MagicSignatures::Key::GENERATOR = 0;
stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Key->generate, 'Key generation fails');
  },
  qr/No Math::Prime::Util installed/,
  'Generator missing'
);
is($Crypt::MagicSignatures::Key::GENERATOR, 0, 'No generator');
$Crypt::MagicSignatures::Key::GENERATOR = 1;

ok($key->n, 'Modulus');
ok($key->e, 'Public Exponet');
ok($key->d, 'Private Exponet');

is($key->e, 3, 'Public exponent is correct');
is(_b($key->n), 1024, 'Modulus-Size is correct');


{
  local $SIG{__WARN__} = sub {};

  ok($sig = $key->sign('This is a new message'), 'Signing');
  ok($key->verify('This is a new message', $sig), 'Verification');
  ok(!$key->verify('This is a new message', 'u' . $sig), 'Verification');
  ok(!$key->verify('This is a new message', $sig . 'u'), 'Verification');
};

like($key->to_string, qr/^RSA(\.[-_a-zA-Z0-9]+=*){2}$/, 'Stringification');

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Key->generate(size => 48, e => 3), 'Key Generation');
  },
  qr/key size/i,
  'Too small'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Key->generate(size => 513, e => 3), 'Key Generation');
  },
  qr/key size/i,
  'Too uneven'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Key->generate(size => 7000, e => 3), 'Key Generation');
  },
  qr/key size/i,
  'Too large'
);


{
  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  $Crypt::MagicSignatures::Key::MAX_GEN_ROUNDS = 5;

  my $name = subname( \&random_nbit_prime );


  is($name, 'Math::Prime::Util::random_nbit_prime', 'Correct subname');

  # Overwrite random_nbit_prime generation to fail
  *{"$name"} =
    *{'random_nbit_prime'} =
    *{'Math::Prime::Util::PP::random_nbit_prime'} =
    *{'Math::Prime::Util::RandomPrimes::random_nbit_prime'} =
    *{'Math::Prime::Util::GMP::random_nbit_prime'} =
    sub ($) {
      return 5;
    };

  is(random_nbit_prime(456), 5, 'Correctly overwritten');


  stderr_like(
    sub {
      ok(!Crypt::MagicSignatures::Key->generate(), 'Key Generation');
    },
    qr/maximum/i,
    'Maximum rounds'
  );
}

done_testing;
