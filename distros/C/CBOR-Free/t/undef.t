#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use_ok('CBOR::Free');

is( CBOR::Free::encode(undef), "\xf6", 'undef encodes ok' );

done_testing;
