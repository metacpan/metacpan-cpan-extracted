#!/usr/bin/perl
use utf8;
use Test::More;
use Crypto::Utils::OpenSSL;

# Test vector from RFC 7914:
# password = "password"
# salt = "NaCl"
# N = 1024, r = 8, p = 16
# output length = 64
# expected output (hex): fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640

my $key = scrypt( 'password', 'NaCl', 1024, 8, 16, 64 );
is(
    unpack( "H*", $key ),
'fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640',
    'scrypt RFC 7914 test vector'
);

done_testing();
