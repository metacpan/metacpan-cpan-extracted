#!/usr/bin/env perl

use Test::Most;
plan tests => 6;
bail_on_fail if 0;
use Env::Path 0.18 'PATH';

ok(scalar PATH->Whence($_), "$_ in PATH") for qw(awk samtools gunzip gzip smalt tabix);

