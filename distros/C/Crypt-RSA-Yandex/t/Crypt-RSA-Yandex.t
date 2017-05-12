#!/usr/bin/env perl

use strict;
use Test::More tests => 9;
use MIME::Base64 ();
use Crypt::RSA::Yandex qw(ya_encrypt);

my $pub_key = 'BFC949E4C7ADCC6F179226D574869CBF44D6220DA37C054C64CE48D4BAA36B039D8206E45E4576BFDB1D3B40D958FF0894F6541717824FDEBCEDD27C4BE1F057#10001';
my $text    = '12345';
my $expect  =  MIME::Base64::decode('BQBAAKypbGqp3y2TkI4ZwEbpOmsRjBb/JIgd8Px4UcDewPi/bGGJiiDVSHUKa6kxIRRGqXvgbiPHcpO2R/3KEZ6tHRQ=');

is( ya_encrypt($pub_key,$text), $expect, 'text correctly encrypted' );
ok my $crypter = Crypt::RSA::Yandex->new, 'object created';
$crypter->import_public_key($pub_key);

is $crypter->encrypt($text), $expect, 'text correctly encrypted';

for my $bad_key (
	'BFC949E4C7ADCC6F179226D574869CBF44D6220DA37C054C64CE48D4BAA36B039D8206E45E4576BFDB1D3B40D958FF0894F6541717824FDEBCEDD27C4BE1F057',
	'BFC949E4C7ADCC6F179226D574869CBF44D6220DA37C054C64CE48D4BAA36B039D8206E45E4576BFDB1D3B40D958FF0894F6541717824FDEBCEDD27C4BE1F057#',
	'#',
) {
    ok !eval{ ya_encrypt($bad_key,$text); 1 }, 'died';
    ok $@, 'have error';
}
