#!/usr/bin/perl -w

use lib 't';
use Testdata;

use Test::More tests => 15*@ciphers + 4;

BEGIN { use_ok (Crypt::ECB) }

my $ecb = Crypt::ECB->new;

eval { $ecb->cipher('DES') };
SKIP: {	skip "'DES' not installed", 3 if $@;

	$ecb = Crypt::ECB->new($key);
	ok($ecb->key     eq $key,	"DES, options very old style: key");
	ok($ecb->cipher  eq 'DES',	"DES, options very old style: cipher");
	ok($ecb->padding eq 'standard',	"DES, options very old style: padding");
}

foreach my $cipher (@ciphers)
{
	eval { $ecb->cipher($cipher) };
	SKIP: {	skip "$cipher not installed", 15 if $@;

		$ecb = Crypt::ECB->new($key => $cipher);
		ok($ecb->key     eq $key,		"$cipher, options very old style: key");
		ok($ecb->cipher  eq $cipher,		"$cipher, options very old style: cipher");
		ok($ecb->padding eq 'standard',		"$cipher, options very old style: padding");

		$ecb = Crypt::ECB->new( {key => $key, cipher => $cipher, padding => 'oneandzeroes'} );
		ok($ecb->key     eq $key,		"$cipher, options old style: key");
		ok($ecb->cipher  eq $cipher,		"$cipher, options old style: cipher");
		ok($ecb->padding eq 'oneandzeroes',	"$cipher, options old style: padding");

		$ecb = Crypt::ECB->new(-key => $key, -cipher => $cipher, -padding => 'oneandzeroes');
		ok($ecb->key     eq $key,		"$cipher, options new style: key");
		ok($ecb->cipher  eq $cipher,		"$cipher, options new style: cipher");
		ok($ecb->padding eq 'oneandzeroes',	"$cipher, options new style: padding");

		$ecb = Crypt::ECB->new(-cipher => $cipher);
		ok($ecb->cipher    eq $cipher,			"$cipher, options new style: cipher");
		ok($ecb->keysize   == $ecb->module->keysize,	"$cipher, options new style: keysize");
		ok($ecb->blocksize == $ecb->module->blocksize,	"$cipher, options new style: blocksize");

		$ecb = Crypt::ECB->new(-cipher => $cipher, -keysize => 10, -blocksize => 10);
		ok($ecb->cipher    eq $cipher,		"$cipher, options new style: cipher");
		ok($ecb->keysize   == 10,		"$cipher, options new style: keysize override");
		ok($ecb->blocksize == 10,		"$cipher, options new style: blocksize override");
	}
}
