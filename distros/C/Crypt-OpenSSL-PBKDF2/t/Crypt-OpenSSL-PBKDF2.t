use Test::More tests => 19;

BEGIN { use_ok('Crypt::OpenSSL::PBKDF2') };

SCOPE: {
	# check derive using RFC7060 test vectors
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 1, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '0c60c80f961f0e71f3a9b524af6012062fe037a6', "derive: p=password, s=salt, l=4, c=1, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 2, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957', "derive: p=password, s=salt, l=4, c=2, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 4096, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4b007901b765489abead49d926f721d065a429c1', "derive: p=password, s=salt, l=4, c=4096, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 16777216, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'eefe3d61cd4da4e4e9945b3d6ba2158c2634e984', "derive: p=password, s=salt, l=4, c=16777216, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 36, 4096, 25);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038', "derive: p=passwordPASSWORDpassword, s=saltSALTsaltSALTsaltSALTsaltSALTsalt, l=36, c=4096, k=25" );
	# derive should truncate password on NUL
	$a = Crypt::OpenSSL::PBKDF2::derive("pass\0word", "salt", 4, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4cefcc92209453e3923e855751c7b10e', "derive: p=pass\\0word, s=salt, l=4, c=4096, k=16" );
	# derive should not truncate salt on NUL
	$a = Crypt::OpenSSL::PBKDF2::derive("password", "sa\0lt", 5, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '22c159d1a94adf95533ef8f65e40091a', "derive: p=pass, s=sa\\0lt, l=5, c=4096, k=16" );
	# test derive for other hashing algotithm (different from default)
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 1, 20, 'sha256');
	cmp_ok( join('', unpack('H*', $a)), 'eq', '120fb6cffcf8b32c43e7225256c4f837a86548c9', "derive: p=password, s=salt, l=4, c=1, k=20, a=sha256" );
	# test derive for an invalid hashing algotithm
	eval { Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 1, 20, 'sha') };
	chomp $@;
	ok( $@ =~ /^invalid hashing algorithm/, "derive: p=password, s=salt, l=4, c=1, k=20, a=sha" );

	# check derive_bin using RFC7060 test vectors
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', 8, 'salt', 4, 1, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '0c60c80f961f0e71f3a9b524af6012062fe037a6', "derive: p=password, n=8, s=salt, l=4, c=1, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', 8, 'salt', 4, 2, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957', "derive: p=password, n=8, s=salt, l=4, c=2, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', 8, 'salt', 4, 4096, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4b007901b765489abead49d926f721d065a429c1', "derive: p=password, n=8, s=salt, l=4, c=4096, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', 8, 'salt', 4, 16777216, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'eefe3d61cd4da4e4e9945b3d6ba2158c2634e984', "derive: p=password, n=8, s=salt, l=4, c=16777216, k=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('passwordPASSWORDpassword', 24, 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 36, 4096, 25);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038', "derive: p=passwordPASSWORDpassword, n=24, s=saltSALTsaltSALTsaltSALTsaltSALTsalt, l=36, c=4096, k=25" );
	# check if derive_bin ignores NUL into password
	$a = Crypt::OpenSSL::PBKDF2::derive_bin("pass\0word", 9, "salt", 4, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'e660ca4a7a28e5398855f42f485f89ad', "derive_bin: p=pass\\0word, n=9, s=salt, l=4, c=4096, k=16" );
	# check derive_bin auto-length
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', -1, 'salt', 4, 4096, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4b007901b765489abead49d926f721d065a429c1', "derive_bin: p=password, n=-1, s=salt, l=4, c=4096, k=20" );
	# test derive_bin other hashing algotithm (different from default)
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', -1, 'salt', 4, 1, 20, 'sha512');
	cmp_ok( join('', unpack('H*', $a)), 'eq', '867f70cf1ade02cff3752599a3a53dc4af34c7a6', "derive: p=password, n=-1, s=salt, l=4, c=1, k=20, a=sha512" );
	# test derive_bin for an invalid hashing algotithm
	eval { Crypt::OpenSSL::PBKDF2::derive('password', -1, 'salt', 4, 1, 20, 'sha') };
	chomp $@;
	ok( $@ =~ /^invalid hashing algorithm/, "derive: p=password, n=-1, s=salt, l=4, c=1, k=20, a=sha" );
}

