use Test::More;
use Authen::Passphrase::Argon2;

my $ppr = Authen::Passphrase::Argon2->new(
	salt => 'abcdefg123',
	passphrase => 'abc'
);

is($ppr->algorithm, 'Argon2', 'Yep we are Argon2');
is($ppr->salt, 'abcdefg123', 'expected salt');
is($ppr->salt_hex, '61626364656667313233', 'expected hex salt');
is($ppr->salt_base64, 'YWJjZGVmZzEyMw==
', 'expected salt base64');
is($ppr->as_crypt, '$argon2i$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$CSH832cJc04svQovVI/uDA', 'expected crypt value - argon2');
is($ppr->hash, '$argon2i$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$CSH832cJc04svQovVI/uDA', 'expected crypt value - argon2');
is($ppr->hash_hex, '246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441', 'expected hash hex - crypt hex - 246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441');
is($ppr->hash_base64, 'JGFyZ29uMmkkdj0xOSRtPTMyNzY4LHQ9MyxwPTEkWVdKalpHVm1aekV5TXckQ1NIODMyY0pjMDRz
dlFvdlZJL3VEQQ==
', 'expected base64');
is($ppr->match('abc'), 1, 'passphrases match \o/');

$ppr = Authen::Passphrase::Argon2->new(
	salt => 'abcdefg123',
	stored_hex => 1,
	passphrase => '246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441',
);

is($ppr->algorithm, 'Argon2', 'Yep we are Argon2');
is($ppr->salt, 'abcdefg123', 'expected salt');
is($ppr->salt_hex, '61626364656667313233', 'expected hex salt');
is($ppr->salt_base64, 'YWJjZGVmZzEyMw==
', 'expected salt base64');

is($ppr->as_crypt, '$argon2i$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$CSH832cJc04svQovVI/uDA', 'expected crypt value - argon2');

is($ppr->hash, '$argon2i$v=19$m=32768,t=3,p=1$YWJjZGVmZzEyMw$CSH832cJc04svQovVI/uDA', 'expected crypt value - argon2');
is($ppr->hash_hex, '246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441', 'expected hash hex - crypt hex - 246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441');
is($ppr->hash_base64, 'JGFyZ29uMmkkdj0xOSRtPTMyNzY4LHQ9MyxwPTEkWVdKalpHVm1aekV5TXckQ1NIODMyY0pjMDRz
dlFvdlZJL3VEQQ==
', 'expected base64');
is($ppr->match('abc'), 1, 'passphrases match \o/');

done_testing();
