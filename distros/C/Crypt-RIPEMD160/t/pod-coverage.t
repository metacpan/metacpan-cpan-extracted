#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Author testing" unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required" if $@;

pod_coverage_ok('Crypt::RIPEMD160', { trustme => [qr/^DESTROY$/] });

# MAC.pm documents its methods in the DESCRIPTION prose rather than
# with =head2 sections; trust all public methods for now.
pod_coverage_ok('Crypt::RIPEMD160::MAC',
    { trustme => [qr/^(?:new|reset|add|addfile|mac|hexmac)$/] });

done_testing;
