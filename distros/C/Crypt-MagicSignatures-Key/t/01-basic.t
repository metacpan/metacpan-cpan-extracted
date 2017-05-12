#!/usr/bin/env perl
use Test::More;
use Math::BigInt try => 'GMP,Pari';
use strict;
use warnings;
no strict 'refs';

use lib '../lib';

our $module;
BEGIN {
  our $module = 'Crypt::MagicSignatures::Key';
  use_ok($module, qw/b64url_encode b64url_decode/);   # 1
};

my $test_msg = 'This is a small message test.';

# test os2ip
my $os2ip = *{"${module}::_os2ip"}->($test_msg);
ok($os2ip eq '22756313778701413365784'.
             '01782410999343477943894'.
             '174703601131715860591662', 'os2ip'); # 2

# test i2osp
my $i2osp = *{"${module}::_i2osp"}->($os2ip);
ok($i2osp eq $test_msg, 'i2osp');                  # 3

# test bitsize
my $bitsize = *{"${module}::_bitsize"}->($os2ip);
is(231, $bitsize, 'bitsize');                    # 4

# test octet_len
my $octet_len = *{"${module}::_octet_len"}->($os2ip);
is(29, $octet_len, 'octet_len');                 # 5

# test b64url_encode
my $b64url_encode = b64url_encode($test_msg);
$b64url_encode =~ s/[\s=]+$//;
is($b64url_encode, 'VGhpcyBpcyBhIHNtYWxsIG1lc3NhZ2UgdGVzdC4',
   'b64url_encode');                               # 6

# test b64url_decode
my $b64url_decode = b64url_decode($b64url_encode);
ok($b64url_decode eq $test_msg, 'b64url_decode');  # 7

is('', b64url_decode(), 'No Message passed');
is('', b64url_encode(), 'No Message passed');

# test _hex_to_b64url
my $hex2b64url = *{"${module}::_hex_to_b64url"}->($os2ip);
$b64url_encode =~ s/[\s=]+$//;
is($hex2b64url, b64url_encode($test_msg), '_hex_to_b64url');

# test _b64url_to_hex
my $b64url2hex = *{"${module}::_b64url_to_hex"}->(b64url_encode($test_msg));
is($b64url2hex, $os2ip, '_b64url_to_hex');

# test _b64url_to_hex with unknown characters
$b64url2hex = *{"${module}::_b64url_to_hex"}->(',' . b64url_encode($test_msg) . ',');
is($b64url2hex, $os2ip, '_b64url_to_hex');


# MaxMin tests #
################

$test_msg = ('abc' x 33 . 'def' x 33 . 'ghi' x 33 . 'jkl');

# test os2ip
$os2ip = *{"${module}::_os2ip"}->($test_msg);
ok($os2ip, 'os2ip');

# > 30_000 characters
$os2ip = *{"${module}::_os2ip"}->($test_msg x 110);
ok(!$os2ip, 'os2ip fail');

$os2ip = *{"${module}::_os2ip"}->('');
ok(!$os2ip, 'os2ip');

$os2ip = *{"${module}::_os2ip"}->('1');
is($os2ip, '49', 'os2ip');

$os2ip = *{"${module}::_os2ip"}->("\0");
is($os2ip, '0', 'os2ip');

# _os2ip fails with > 30_000 characters

$os2ip = ('123' x 33 . '345' x 33 . '678' x 33 . '901');

# test i2osp
$i2osp = *{"${module}::_i2osp"}->($os2ip);
ok($i2osp, 'i2osp');                  # 3

$i2osp = *{"${module}::_i2osp"}->($os2ip x 110);
ok(!$i2osp, 'i2osp');

$i2osp = *{"${module}::_i2osp"}->();
ok($i2osp, 'i2osp');

$i2osp = *{"${module}::_i2osp"}->("a");
ok(!$i2osp, 'i2osp');

# test bitsize
$bitsize = *{"${module}::_bitsize"}->($os2ip);
is(994, $bitsize, 'bitsize');                    # 4

$bitsize = *{"${module}::_bitsize"}->(0);
is(0, $bitsize, 'Bitsize 0');

done_testing;
__END__
