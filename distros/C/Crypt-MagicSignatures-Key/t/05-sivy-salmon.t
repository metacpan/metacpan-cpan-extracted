#!/usr/bin/env perl

use Test::More tests => 4;
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

my $test_msg = 'test string';

# https://salmon-protocol.googlecode.com/
#   svn/trunk/lib/python/magicsig_hjfreyer/magicsig_example.py
my $test_key =
    'RSA.'.
    'mVgY8RN6URBTstndvmUUPb4UZTdwvw'.
    'mddSKE5z_jvKUEK6yk1u3rrC9yN8k6'.
    'FilGj9K0eeUPe2hf4Pj-5CmHww==.'.
    'AQAB.'.
    'Lgy_yL3hsLBngkFdDw1Jy9TmSRMiH6'.
    'yihYetQ8jy-jZXdsZXd8V5ub3kuBHH'.
    'k4M39i3TduIkcrjcsiWQb77D8Q==';

my $mkey = Crypt::MagicSignatures::Key->new($test_key);

is($mkey->size, 512, 'Key size is correct');

my $sig = $mkey->sign($test_msg);

# From https://github.com/sivy/Salmon/blob/master/t/30-magic-algorithms.t
my $test_sig = 'mNpBIpTUOESnuQMlS8aWZ4hwdS'.
               'wWnMstrn0F3L9GHDXa238fN3Bx'.
               '3Rl0yvVESM_eZuocLsp9ubUrYD'.
               'u83821fQ==';

is($sig, $test_sig,  'Signature');       # 14

ok($mkey->verify($test_msg, $sig), 'Verification');
