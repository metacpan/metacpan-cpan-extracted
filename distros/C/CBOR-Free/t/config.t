#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Config;

use CBOR::Free ();

my $encoded = CBOR::Free::encode( \%Config );

ok $encoded, 'encoded to CBOR as expected';

my $roundtrip = CBOR::Free::decode($encoded);

is_deeply( $roundtrip, \%Config, q[%Config roundtrip] ) or diag explain $roundtrip;

done_testing;
