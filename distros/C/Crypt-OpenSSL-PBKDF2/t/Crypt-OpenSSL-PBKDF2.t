use Test::More tests => 10;
BEGIN { use_ok('Crypt::OpenSSL::PBKDF2') };

SCOPE: {
	# use RFC7060 test vectors
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 1, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '0c60c80f961f0e71f3a9b524af6012062fe037a6', "derive: P=password, S=salt, c=1, dklen=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 2, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957', "derive: P=password, S=salt, c=2, dklen=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 4096, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4b007901b765489abead49d926f721d065a429c1', "derive: P=password, S=salt, c=4096, dklen=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('password', 'salt', 4, 16777216, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'eefe3d61cd4da4e4e9945b3d6ba2158c2634e984', "derive: P=password, S=salt, c=16777216, dklen=20" );
	$a = Crypt::OpenSSL::PBKDF2::derive('passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 36, 4096, 25);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038', "derive: P=passwordPASSWORDpassword, S=saltSALTsaltSALTsaltSALTsaltSALTsalt, c=4096, dklen=25" );
	# derive should truncate password on NUL
	$a = Crypt::OpenSSL::PBKDF2::derive("pass\0word", "sa\0lt", 5, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'a60ec4632c8f26430456dd4d0f5df1a4', "derive: P=pass\\0word, S=sa\\0lt, c=4096, dklen=16" );
	$a = Crypt::OpenSSL::PBKDF2::derive("pass", "sa\0lt", 5, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', 'a60ec4632c8f26430456dd4d0f5df1a4', "derive: P=pass, S=sa\\0lt, c=4096, dklen=16" );
	# this one pass because it uses derive_bin
	$a = Crypt::OpenSSL::PBKDF2::derive_bin("pass\0word", 9, "sa\0lt", 5, 4096, 16);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '56fa6aa75548099dcc37d7f03425e0c3', "derive_bin: P=pass\\0word, S=sa\\0lt, c=4096, dklen=16" );
	# check derive_bin auto-length
	$a = Crypt::OpenSSL::PBKDF2::derive_bin('password', -1, 'salt', 4, 4096, 20);
	cmp_ok( join('', unpack('H*', $a)), 'eq', '4b007901b765489abead49d926f721d065a429c1', "derive_bin: P=password(auto-length), S=salt, c=4096, dklen=20" );
}

