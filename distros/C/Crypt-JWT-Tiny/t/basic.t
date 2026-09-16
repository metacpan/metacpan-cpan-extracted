#! perl

use strict;
use warnings;

use Test::More;

use Crypt::JWT::Tiny qw/encode_jwt decode_jwt/;
use MIME::Base64 'decode_base64url';

subtest RFC7515 => sub {
	my $key = decode_base64url("AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow");
	my $jws = "eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9".
			  ".eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ".
			  ".dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk";

	my $claims = decode_jwt(token => $jws, key=>$key, alg => 'HS256', time => 1300819370);
	is($claims->{iss}, "joe",  "Section 3.1 claims iss");
	is($claims->{exp}, 1300819380, "Section 3.1 claims exp");
	ok($claims->{"http://example.com/is_root"}, "Section 3.1 claims http://example.com/is_root");
};

subtest 'Basic correctness' => sub {
	my $key = '0123456789ABCDEF0123456789ABCDEF';
	my $token = eval { encode_jwt(claims => { iss => 'me', aud => 'test' }, key => $key, alg => 'HS256', auto_iat => 1) };
	is $@, '', 'No exception thrown by encode';
	ok $token, 'token is defined';
	my $decoded = eval { decode_jwt(token => $token, key => $key, alg => 'HS256') };
	is $@, '', 'No exception thrown by decode';
	ok $decoded, 'Decoded successfully';
	is ref($decoded), 'HASH', 'Decoded value is a hash';
	is $decoded->{iss}, 'me', 'Issuer is me';
	is $decoded->{aud}, 'test', 'Audience is test';

	my $decoded2 = eval { decode_jwt(token => $token, key => $key, alg => 'HS256', iss => 'me', aud => 'test', max_age => 60) };
	is $@, '', 'No exception thrown by second decode';
	ok $decoded2, 'Decoded successfully again';
};

subtest 'Argument typ' => sub {
	my $key = '0123456789ABCDEF0123456789ABCDEF';
	my $token = eval { encode_jwt(claims => {}, key => $key, alg => 'HS256', typ => 'JWT') };
	is $@, '', 'No exception thrown by encode';
	ok $token, 'token is defined';
	my $decoded = eval { decode_jwt(token => $token, key => $key, alg => 'HS256', typ => 'JWT') };
	is $@, '', 'No exception thrown by decode';

	my $decoded2 = eval { decode_jwt(token => $token, key => $key, alg => 'HS256', typ => 'Something') };
	like $@, qr/^Incorrect type/, 'Exception thrown by decode for incorrect type';
	ok !$decoded2, "Shouldn't decode with wrong typ";
};

subtest 'Validation' => sub {
	my $key = '0123456789ABCDEF0123456789ABCDEF';
	my $token = eval { encode_jwt(claims => { iss => 'me', aud => 'test' }, key => $key, alg => 'HS256') };
	is $@, '', 'No exception thrown by encode';
	ok $token, 'token is defined';
	my $decoded = eval { decode_jwt(token => $token, key => $key, alg => 'HS256', iss => 'me', aud => 'test') };
	is $@, '', 'No exception thrown by decode';
	ok $decoded, 'Decoded successfully';
};

done_testing;
