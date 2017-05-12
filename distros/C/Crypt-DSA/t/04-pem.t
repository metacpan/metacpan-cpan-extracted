#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;

BEGIN {
	eval { require Crypt::DES_EDE3 };
	if ( $@ ) {
		Test::More->import( skip_all => 'no Crypt::DES_EDE3' );
	}
	eval { require Convert::PEM };
	if ( $@ ) {
		Test::More->import( skip_all => 'no Convert::PEM' );
	}
	Test::More->import( tests => 26 );
}

use Crypt::DSA;
use Crypt::DSA::Key;
use Crypt::DSA::Signature;

my $keyfile = "./dsa-key.pem";

my $dsa = Crypt::DSA->new;
my $key = $dsa->keygen( Size => 512 );

## Serialize a signature.
my $sig = $dsa->sign(
	Message => 'foo',
	Key     => $key,
);
ok($sig, 'Signature created correctly using Crypt::DSA->sign');
my $buf = $sig->serialize;
ok($buf, 'Signature serialized correctly');
my $sig2 = Crypt::DSA::Signature->new( Content => $buf );
ok($sig2, 'Signature created correctly using Crypt::DSA::Signature');
is($sig2->r, $sig->r, '->r of both signatures is identical');
is($sig2->s, $sig->s, '->s of both signatures is identical');

ok($key->write( Type => 'PEM', Filename => $keyfile), 'Writing key works.');
my $key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2, 'Load key using Crypt::DSA::key');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
is($key->priv_key, $key2->priv_key, '->priv_key of both keys is identical');

ok($key->write( Type => 'PEM', Filename => $keyfile, Password => 'foo'), 'Writing keyfile with password works');
$key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile, Password => 'foo' );
ok($key2, 'Reading keyfile with password works');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
is($key->priv_key, $key2->priv_key, '->priv_key of both keys is identical');

## Now remove the private key portion of the key. write should automatically
## write a public key format instead, and new should be able to understand
## it.
$key->priv_key(undef);
ok($key->write( Type => 'PEM', Filename => $keyfile), 'Writing keyfile without private key works');
$key2 = Crypt::DSA::Key->new( Type => 'PEM', Filename => $keyfile );
ok($key2, 'Reading keyfile without private key works');
is($key->p, $key2->p, '->p of both keys is identical');
is($key->q, $key2->q, '->q of both keys is identical');
is($key->g, $key2->g, '->g of both keys is identical');
is($key->pub_key, $key2->pub_key, '->pub_key of both keys is identical');
ok(!$key->priv_key, 'No private key');

unlink $keyfile;
