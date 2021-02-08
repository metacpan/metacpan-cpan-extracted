#!/usr/local/bin/perl

use lib '../blib/lib','../lib','./lib';
use strict;
use Test;

my $open_ssl_expected;

BEGIN {
    $open_ssl_expected = {
	opensslv1 => {key => 'DFB4CADC622054E432B94423894DED3FF1CD3887DED9E23EB943C316F57A7901',
		      iv  => 'A43CCFB9D40566E759BF1E890833C05D' },
	opensslv2 => {key => '429D56D40A7BAEB4462F9024DB29AD7C3F1ABF6DF91A6AA4EB461D76CA238317',
		      iv  => '104179D56A0EB898EF3254F3F81901C5' },
	pbkdf2 => {iv => '8BD84A68D9F1C640A1530C21D31CAF7C',
		   key=> 'F383A9DF2698C85EF21FCC8C3394182BAA344E733D71A11F65FEE88DC001C01A'},
    };
    plan tests => keys(%$open_ssl_expected) * 2; 
}

use Crypt::CBC::PBKDF;

for my $method (keys %$open_ssl_expected) {
    my $pb = Crypt::CBC::PBKDF->new($method);
    my ($key,$iv) = $pb->key_and_iv('12345678','foobar');
    ok(uc unpack('H*',$key),$open_ssl_expected->{$method}{key});
    ok(uc unpack('H*',$iv),$open_ssl_expected->{$method}{iv});
}

exit 0;
