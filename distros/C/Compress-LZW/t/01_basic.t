#!/usr/bin/env perl

use Test::More tests => 7;

use Compress::LZW;
use strictures;

my $testdata = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ";

ok(
  my $compdata = compress($testdata),
  "Compressed test data"
);
cmp_ok(
  length($compdata), '<', length($testdata),
  "Data compresses smaller"
);

ok(
  my $decompdata = decompress($compdata),
  "Decompressed test data"
);
cmp_ok(
  length($decompdata), '==', length($testdata),
  "Data decompresses to same size"
);
cmp_ok(
  $decompdata, 'eq', $testdata,
  "Decompressed data is unchanged"
);

cmp_ok(
  decompress(compress($testdata)), 'eq', $testdata,
  'one-shot test'
);

$testdata = '12';
cmp_ok(
  decompress(compress($testdata)), 'eq', $testdata,
  'one-shot test - very short'
);
