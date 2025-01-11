#!perl

use strict;
use warnings;

use Test::More;

plan(skip_all => 'crypt not supported') unless eval { crypt('password', 'aa') };

use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(encoder => 'System');

my %supported = map { $_ => 1 } Crypt::Passphrase::System->crypt_subtypes;
note "Your crypt supports: ", join ', ', sort keys %supported;

my $hash1 = $passphrase->hash_password('password');
ok($passphrase->verify_password('password', $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = 'tesvSclXGCVNk';
ok($passphrase->verify_password('test1234', $hash2), 'descrypt works');

for my $type (Crypt::Passphrase::System->crypt_subtypes) {
	my $passphrase = Crypt::Passphrase->new(encoder => {
			module => 'System',
			type   => $type,
		}
	);

	subtest "Testing type '$type'", sub {
		my $hash = $passphrase->hash_password('password');
		note "Hash is $hash";
		ok($passphrase->verify_password('password', $hash), 'Self-generated password validates');
		ok(!$passphrase->needs_rehash($hash), 'Self-generated password doesn\'t need to be regenerated');
	};
}

SKIP: {
	skip 'no SHACrypt', 1 unless $supported{6};
	my $hash3 = crypt('password', '$6$rounds=100000$AAAAAAAAAAAAAAAAAAAAAA');
	ok($passphrase->verify_password('password', $hash3), 'SHAcrypt works');
}

SKIP: {
	skip 'no bcrypt', 1 unless $supported{'2b'};
	my $hash4 = '$2b$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2';
	ok($passphrase->verify_password('password', $hash4), 'bcrypt works');
}

SKIP: {
	skip 'no yescrypt', 1 unless $supported{y};
	my $hash5 = '$y$j9T$F5Jx5fExrKuPp53xLKQ..1$tnSYvahCwPBHKZUspmcxMfb0.WiB9W.zEaKlOBL35rC';
	ok($passphrase->verify_password('password', $hash5), 'bcrypt works');
}

done_testing;

