use warnings;
use strict;

use Test::More tests => 58;

BEGIN { use_ok "Authen::Passphrase::DESCrypt"; }

my $ppr = Authen::Passphrase::DESCrypt
		->new(fold => 1, initial_base64 => "6UN3gAqtTbM",
		      nrounds_base64 => "xIw.",
		      salt_base64 => "a.rS", hash_base64 => "7KB8x6lwIKQ");
ok $ppr;
ok $ppr->fold;
is $ppr->initial, "\x22\x06\x45\xb0\xcd\xb9\x7e\x76";
is $ppr->initial_base64, "6UN3gAqtTbM";
is $ppr->nrounds, 247101;
is $ppr->nrounds_base64_4, "xIw.";
is $ppr->salt, 8089638;
eval { $ppr->salt_base64_2 }; isnt $@, "";
is $ppr->salt_base64_4, "a.rS";
is $ppr->hash, "\x25\x63\x4a\xf4\x8c\x7c\x51\x67";
is $ppr->hash_base64, "7KB8x6lwIKQ";

$ppr = Authen::Passphrase::DESCrypt
		->new(fold => 0, initial => "\xd7\xa4\x74\xf6\xe1\x42\x84\x4d",
		      nrounds => 9968263, salt => 10354060,
		      hash => "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial, "\xd7\xa4\x74\xf6\xe1\x42\x84\x4d";
is $ppr->initial_base64, "puFoxi30V2o";
is $ppr->nrounds, 9968263;
is $ppr->nrounds_base64_4, "5e/a";
is $ppr->salt, 10354060;
eval { $ppr->salt_base64_2 }; isnt $@, "";
is $ppr->salt_base64_4, "AqTb";
is $ppr->hash, "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82";
is $ppr->hash_base64, "Vcrdw3tDWc6";

$ppr = Authen::Passphrase::DESCrypt
		->new(salt_base64 => "ab",
		      hash => "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial, "\x00\x00\x00\x00\x00\x00\x00\x00";
is $ppr->initial_base64, "...........";
is $ppr->nrounds, 25;
is $ppr->nrounds_base64_4, "N...";
is $ppr->salt, 2534;
is $ppr->salt_base64_2, "ab";
is $ppr->salt_base64_4, "ab..";
is $ppr->hash, "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82";
is $ppr->hash_base64, "Vcrdw3tDWc6";

$ppr = Authen::Passphrase::DESCrypt
		->new(salt => 2534,
		      hash => "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial, "\x00\x00\x00\x00\x00\x00\x00\x00";
is $ppr->initial_base64, "...........";
is $ppr->nrounds, 25;
is $ppr->nrounds_base64_4, "N...";
is $ppr->salt, 2534;
is $ppr->salt_base64_2, "ab";
is $ppr->salt_base64_4, "ab..";
is $ppr->hash, "\x86\x8d\xe9\xf0\x5e\x4f\x8a\x82";
is $ppr->hash_base64, "Vcrdw3tDWc6";

$ppr = Authen::Passphrase::DESCrypt
		->new(salt => 2534,
		      passphrase => "wibble");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial_base64, "...........";
is $ppr->nrounds_base64_4, "N...";
is $ppr->salt_base64_4, "ab..";
is $ppr->hash_base64, "Fj33Wj0Z5j.";

$ppr = Authen::Passphrase::DESCrypt
		->new(salt_random => 12,
		      passphrase => "wibble");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial_base64, "...........";
is $ppr->nrounds_base64_4, "N...";
like $ppr->salt_base64_4, qr/\A..\.\.\z/;
is length($ppr->hash), 8;
ok $ppr->match("wibble");

1;
