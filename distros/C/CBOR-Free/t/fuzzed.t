#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use Data::Dumper;
use FindBin;

use CBOR::Free;

my $fuzzed_dir = "$FindBin::Bin/fuzzed";

opendir( my $dh, $fuzzed_dir );

while ( my $node = readdir $dh ) {
    next if $node =~ tr<.><>;

    open my $rfh, '<:raw', "$fuzzed_dir/$node";
    my $cbor = do { local $/; <$rfh> };

    eval {
        local $SIG{'__WARN__'} = sub {};
        CBOR::Free::decode($cbor);
    };

    ok 1, "$node: still alive";
}

done_testing;
