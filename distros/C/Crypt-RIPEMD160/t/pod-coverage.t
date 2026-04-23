#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Author testing" unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required" if $@;

pod_coverage_ok('Crypt::RIPEMD160', { trustme => [qr/^DESTROY$/] });

pod_coverage_ok('Crypt::RIPEMD160::MAC');

done_testing;
