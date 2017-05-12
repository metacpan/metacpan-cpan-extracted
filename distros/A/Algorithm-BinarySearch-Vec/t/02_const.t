# -*- Mode: CPerl -*-
# t/02_const.t; test constants

use Test::More tests => 2;
use Algorithm::BinarySearch::Vec qw(:all);
no warnings 'portable';

ok($KEY_NOT_FOUND == 0xffffffff, "KEY_NOT_FOUND == 32-bit max");
SKIP: {
  skip("quad keys unsupported", 1) if (1); #!$Algorithm::BinarySearch::Vec::HAVE_QUAD);
  #ok($KEY_NOT_FOUND >= 0xffffffffffffffff, "KEY_NOT_FOUND >= 64-bit max");
  ok(0);
}

# end of t/02_const.t
