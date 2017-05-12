#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok(
        "Convert::zBase32",
        { also_private => [ 
#                    qr/^(OH|SE)_.+$/,
#                    qr/^(handler_for|instantiate|set_objectre)$/
                ], 
        },
        "Convert::zBase32, ignoring private functions",
);
