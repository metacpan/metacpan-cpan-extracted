#!/usr/bin/perl

our $NUM_TESTS; BEGIN { $NUM_TESTS = 1_000 };

use strict;
use Test::More tests => $NUM_TESTS;
use Crypt::Juniper;

for (1..$NUM_TESTS)
{
    my $plain = _gen();
    my $encrypt = juniper_encrypt($plain);
    my $decrypt = juniper_decrypt($encrypt);

    is($decrypt, $plain, "decrypt(encrypt('$plain')) correct");
}

sub _gen {
    my $length = int rand(127)+1;
    my $str = '';

    while ($length-- > 0)
    {
        $str .= chr(ord('!') + int rand (ord('~') - ord('!')));
    }
    return $str;
}
