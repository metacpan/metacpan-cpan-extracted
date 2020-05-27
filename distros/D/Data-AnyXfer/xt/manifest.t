#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

BEGIN {
    use Data::AnyXfer;
    Data::AnyXfer->test(1);
}

use Test::CheckManifest;

ok_manifest({ filter => [ qr/~$/ ] }, "Manifest okay");
