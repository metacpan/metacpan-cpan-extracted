#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 17;
use Test::Fatal;

my $pw;
my $salt = 'abcdefghijklmnop';
my $pass = 'something';

use_ok('App::Raps2::Password');

like(
	exception {
		App::Raps2::Password->new();
	},
	qr{no passphrase given},
	'new() missing passphrase'
);

like(
	exception {
		App::Raps2::Password->new(
			salt => $salt,
			passphrase => q{}
		);
	},
	qr{no passphrase given},
	'new() missing passphrase'
);

like(
	exception {
		App::Raps2::Password->new(
			passphrase => $pass,
			salt => 'abcdefghijklmno',
		);
	},
	qr{incorrect salt length},
	'new() salt one too short'
);

like(
	exception {
		App::Raps2::Password->new(
			passphrase => $pass,
			salt => $salt . 'z',
		);
	},
	qr{incorrect salt length},
	'new() salt one too long'
);

$pw = App::Raps2::Password->new(
	passphrase => $pass,
	salt => $salt,
);
isa_ok($pw, 'App::Raps2::Password');

$pw = App::Raps2::Password->new(
	cost => 8,
	salt => $salt,
	passphrase => $pass,
);

isa_ok($pw, 'App::Raps2::Password');

is($pw->decrypt(data => '53616c7465645f5f80d8c367e15980d43ec9a6eabc5390b4'), 'quux',
	'decrypt okay');

is($pw->decrypt(data => $pw->encrypt(data => 'foo')), 'foo', 'encrypt->decrypt okay');

ok($pw->verify('3lJRlaRuOGWv/z3g1DAOlcH.u9vS8Wm'), 'verify: verifies correct hash');

like(
	exception {
		$pw->verify('3lJRlaRuOGWv/z3g1DAOlcH.u9vS8WM');
	},
	qr{Passwords did not match},
	'verify: does not verify invalid hash'
);

ok($pw->verify($pw->bcrypt('truth')), 'bcrypt->verify okay');

is($pw->salt(), $salt, 'salt() returns current salt');

like(
	exception {
		$pw->salt('');
	},
	qr{incorrect salt length},
	'salt: Empty argument',
);

like(
	exception {
		$pw->salt('abcdefghijklmno');
	},
	qr{incorrect salt length},
	'salt: One too short',
);

like(
	exception {
		$pw->salt($salt . 'z');
	},
	qr{incorrect salt length},
	'salt: One too long',
);

is(
	exception {
		$pw->salt($salt);
	},
	undef,
	'salt: Correct length',
);
