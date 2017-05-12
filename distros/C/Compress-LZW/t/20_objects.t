#!/usr/bin/env perl

use Test::More;

use Compress::LZW::Compressor;
use Compress::LZW::Decompressor;
use strictures;

my $testdata = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";



my $c = new_ok( 'Compress::LZW::Compressor', undef, 'compressor' );
can_ok( $c, qw( compress reset block_mode max_code_size ) );

ok(
  my $compdata = $c->compress($testdata),
  "Compressed test data"
);

cmp_ok(
  length($compdata), '<', length($testdata),
  "Data compresses smaller"
);

ok(
  my $compdata2 = $c->compress($testdata),
  'Reuse compressor, implicit ->reset'
);

cmp_ok(
  $compdata, 'eq', $compdata2,
  'Same output from once-used instance'
);


my $d = new_ok( 'Compress::LZW::Decompressor', undef, 'decompressor' );
can_ok( $d, qw( decompress reset ) );

ok(
  my $decompdata = $d->decompress($compdata),
  'Data decompresses',
);
cmp_ok(
  length($decompdata), '==', length($testdata),
  "Data decompresses to same size"
);
cmp_ok(
  $decompdata, 'eq', $testdata,
  "Data is unchanged"
);

ok(
  my $decompdata2 = $d->decompress($compdata),
  'Reuse decompressor',
);
cmp_ok(
  $decompdata2, 'eq', $decompdata,
  "Data is decompressed the same after object reuse"
);


done_testing();
