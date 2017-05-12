#!/usr/bin/env perl

use Test::More tests => 9;
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

# tests from https://github.com/bendiken/rsa
{
  local $SIG{__WARN__} = sub {};
  is(*{"${module}::_i2osp"}->(9_202_000, 2), undef, 'Ruby-RSA i2osp - 1');
};
is(*{"${module}::_i2osp"}->(9_202_000, 3), "\x8C\x69\x50", 'Ruby-RSA i2osp - 2');
is(*{"${module}::_i2osp"}->(9_202_000, 4), "\x00\x8C\x69\x50", 'Ruby-RSA i2osp - 3');
is(*{"${module}::_i2osp"}->(9_202_000, 5), "\x00\x00\x8C\x69\x50", 'Ruby-RSA i2osp - 4');

is(*{"${module}::_os2ip"}->("\x8C\x69\x50"), 9_202_000, 'Ruby-RSA os2ip - 1');
is(*{"${module}::_os2ip"}->("\x00\x8C\x69\x50"), 9_202_000, 'Ruby-RSA os2ip - 2');
is(*{"${module}::_os2ip"}->("\x00\x00\x8C\x69\x50"), 9_202_000, 'Ruby-RSA os2ip - 3');
is(*{"${module}::_os2ip"}->("\x00"), 0, 'Ruby-RSA os2ip - 4');
