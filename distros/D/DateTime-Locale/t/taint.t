#!perl -T

use strict;
use warnings;

use Scalar::Util 'tainted';
use Test2::V0;

use DateTime::Locale;

skip_all 'Taint mode is not enabled' unless ${^TAINT};

# Concat code with zero bytes of executable name in order to taint it.
my $code = 'en-GB' . substr $^X, 0, 0;

ok( tainted($code), '$code is tainted' );

try_ok(
    sub {
        is(
            DateTime::Locale->load($code)->code, $code,
            'loaded correct code'
        );
    },
    'tainted load lives'
);

done_testing;
