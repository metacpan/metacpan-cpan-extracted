#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
  if ( eval { require Convert::PEM; 1; } ) {
    plan tests => 28;
  } else {
    plan skip_all => 'Requires Convert::PEM';
  }
}

use Crypt::DSA::GMP;
use Crypt::DSA::GMP::Key;
use Crypt::DSA::GMP::Signature;

my $keyfile = "./dsa-key.pem";

my $dsa = Crypt::DSA::GMP->new;
my $key = $dsa->keygen( Size => 384, NonBlockingKeyGeneration => 1 );

## Serialize a signature.
my $sig = $dsa->sign(
	Message => 'foo',
	Key     => $key,
);
ok($sig, 'Signature created correctly using Crypt::DSA::GMP->sign');
my $buf = $sig->serialize;
ok($buf, 'Signature serialized correctly');
my $sig2 = Crypt::DSA::GMP::Signature->new( Content => $buf );
ok($sig2, 'Signature created correctly using Crypt::DSA::GMP::Signature');
is($sig2->r, $sig->r, '->r of both signatures is identical');
is($sig2->s, $sig->s, '->s of both signatures is identical');

ok($key->write( Type => 'PEM', Filename => $keyfile), 'Writing key works.');
my $key2 = Crypt::DSA::GMP::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2, 'Load key using Crypt::DSA::GMP::key');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
is($key->priv_key, $key2->priv_key, '->priv_key of both keys is identical');

ok($key->write( Type => 'PEM', Filename => $keyfile, Password => 'foo'), 'Writing keyfile with password works');
$key2 = Crypt::DSA::GMP::Key->new( Type => 'PEM', Filename => $keyfile, Password => 'foo' );
ok($key2, 'Reading keyfile with password works');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
is($key->priv_key, $key2->priv_key, '->priv_key of both keys is identical');
unlink $keyfile;

## Now remove the private key portion of the key. write should automatically
## write a public key format instead, and new should be able to understand
## it.
$key->priv_key(undef);
ok($key->write( Type => 'PEM', Filename => $keyfile), 'Writing keyfile without private key works');
$key2 = Crypt::DSA::GMP::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2, 'Reading keyfile without private key works');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
ok(!$key->priv_key, 'No private key');
unlink $keyfile;

ok($key->write( Filename => $keyfile), 'Writing keyfile with native type works');
$key2 = Crypt::DSA::GMP::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2, 'Reading keyfile without private key works');

unlink $keyfile;
