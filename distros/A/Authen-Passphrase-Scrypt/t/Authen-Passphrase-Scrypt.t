#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Authen::Passphrase::Scrypt') };

# Vectors in the scrypt paper
my @vectors = (
	['', '', 4, 1, 1, 64, '77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906'],
	['password', 'NaCl', 10, 8, 16, 64, 'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640'],
	['pleaseletmein', 'SodiumChloride', 14, 8, 1, 64, '7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887'],
	# Vector 4 omitted for performance reasons
);

for (1 .. @vectors) {
	my ($pw, $salt, $logN, $r, $p, $len, $expected) = @{$vectors[$_ - 1]};
	my $result = crypto_scrypt $pw,  $salt, (1 << $logN), $r, $p, $len;
	$result = unpack 'H*', $result;
	is $result, $expected, "Test vector $_"
}

my $x = Authen::Passphrase::Scrypt->new({
	passphrase => 'password1'
});

ok $x->match('password1'), 'new + match';
ok !$x->match('password2'), 'new + match';

my $test_rfc2307 = '{SCRYPT}c2NyeXB0AAwAAAAIAAAAAZ/+bp8gWcTZgEC7YQZeLLyxFeKRRdDkwbaGeFC0NkdUr/YFAWY/UwdOH4i/PxW48fXeXBDOTvGWtS3lLUgzNM0PlJbXhMOGd2bke0PvTSnW';

$x = Authen::Passphrase::Scrypt->from_rfc2307($test_rfc2307);
ok !$x->match('password1'), 'from_rfc2307 + match';
ok $x->match('password2'), 'from_rfc2307 + match';

my $y = Authen::Passphrase::Scrypt->new({
	passphrase => 'password2',
	salt => $x->salt,
	logN => $x->logN,
	r => 8,
});

is $y->as_rfc2307, $test_rfc2307, 'as_rfc2307';
