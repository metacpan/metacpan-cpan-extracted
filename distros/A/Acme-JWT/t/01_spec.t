#!/usr/bin/env perl

use Test::More;

use Acme::JWT;
use Crypt::OpenSSL::RSA;
use Data::Dumper;

sub is_d {
    my ($got, $expected, $test_name) = @_;
    local $Data::Dumper::Terse = 1;
    is(Data::Dumper->Dump([$got]), Data::Dumper->Dump([$expected]), $test_name);
}

my $payload = {foo => 'bar'};

{
    my $name = 'encodes and decodes JWTs';
    my $secret = 'secret';
    my $jwt = Acme::JWT->encode($payload, $secret);
    my $decoded_payload = Acme::JWT->decode($jwt, $secret);
    is_d $decoded_payload, $payload, $name;
}


{
    my $algorithm = 'HS512';
    if ($Acme::JWT::has_sha2) {
        $algorithm = 'RS256';
    }
    my $name = 'encodes and decodes JWTs for RSA signaturese';
    my $rsa = Crypt::OpenSSL::RSA->generate_key(512);
    my $jwt = Acme::JWT->encode($payload, $rsa->get_private_key_string, $algorithm);
    my $decoded_payload = Acme::JWT->decode($jwt, $rsa->get_public_key_string);
    is_d $decoded_payload, $payload, $name;
}

{
    my $name = 'decodes valid JWTs';
    my $example_payload = {hello => 'world'};
    my $example_secret = 'secret';
    my $example_jwt = 'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJoZWxsbyI6ICJ3b3JsZCJ9.tvagLDLoaiJKxOKqpBXSEGy7SYSifZhjntgm9ctpyj8';
    my $decoded_payload = Acme::JWT->decode($example_jwt, $example_secret);
    is_d $decoded_payload, $example_payload, $name;
}

{
    my $name = 'raises exception with wrong hmac key';
    my $right_secret = 'foo';
    my $bad_secret = 'bar';
    my $jwt_message = Acme::JWT->encode($payload, $right_secret, 'HS256');
    eval {
        Acme::JWT->decode($jwt_message, $bad_secret);
    };
    like $@, qr/^Signature verifacation failed/, $name;
}

{
    my $name = 'raises exception with wrong rsa key';
    my $right_rsa = Crypt::OpenSSL::RSA->generate_key(512);
    my $bad_rsa = Crypt::OpenSSL::RSA->generate_key(512);
    my $jwt = Acme::JWT->encode($payload, $right_rsa->get_private_key_string, 'RS256');
    eval {
        Acme::JWT->decode($jwt, $bad_rsa->get_public_key_string);
    };
    like $@, qr/^Signature verifacation failed/, $name;
}

{
    my $name = 'allows decoding without key';
    my $right_secret = 'foo';
    my $bad_secret = 'bar';
    my $jwt = Acme::JWT->encode($payload, $right_secret);
    my $decoded_payload = Acme::JWT->decode($jwt, $bad_secret, 0);
    is_d $decoded_payload, $payload, $name;
}

{
    my $name = 'raises exception on unsupported crypto algorithm';
    eval {
        Acme::JWT->encode($payload, 'secret', 'HS1024');
    };
    like $@, qr/^Unsupported signing method/, $name;
}

{
    my $name = 'encodes and decodes plaintext JWTs';
    my $jwt = Acme::JWT->encode($payload, undef, 0);
    is((my @a = split(/\./, $jwt)), 2, $name . '(length)');
    my $decoded_payload = Acme::JWT->decode($jwt, undef, 0);
    is_d $decoded_payload, $payload, $name;
}

done_testing;
