#!/usr/bin/env perl

use Test::More;

use Compress::LZW::Compressor;
use Compress::LZW::Decompressor;
use strictures;

my $testdata = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. ";
#   $testdata .= $testdata x 3;

my $d = new_ok( 'Compress::LZW::Decompressor', undef, 'default decompressor' );

subtest '9-bit blockless compression' => sub {
  plan tests => 4;

  my $c = new_ok(
    'Compress::LZW::Compressor',
    [ max_code_size => 9, block_mode => 0 ],
    '9-bit blockless compressor'
  );

  ok(
    my $compdata = $c->compress($testdata),
    "Compressed test data"
  );
  cmp_ok(
    length($compdata), '<', length($testdata),
    "Data compresses smaller"
  );

  cmp_ok(
    $d->decompress($compdata), 'eq', $testdata,
    'Data decompresses unchanged'
  );
};


for my $bits ( 9, 12 ) {
  subtest "${bits}-bit block compression" => sub {
    plan tests => 4;

    my $c = new_ok(
      'Compress::LZW::Compressor',
      [ max_code_size => $bits ],
      "${bits}-bit compressor"
    );

    ok(
      my $compdata = $c->compress($testdata),
      "Compressed test data"
    );
    cmp_ok(
      length($compdata), '<', length($testdata),
      "Data compresses smaller"
    );

    cmp_ok(
      $d->decompress($compdata), 'eq', $testdata,
      'Data decompresses unchanged'
    );
  };
}

subtest '24-bit compression' => sub {
  plan tests => 4;

  my $c = new_ok(
    'Compress::LZW::Compressor',
    [ max_code_size => 24 ],
    '24-bit compressor'
  );
  
  my $repeat = 15_000;
  note( 'Test data size: ' . length($testdata)*$repeat );
  
  ok(
    my $compdata = $c->compress($testdata x $repeat),
    "Compressed test data"
  );
  note( 'Final bits: '.$c->{code_size} );
  
  cmp_ok(
    length($compdata), '<', length($testdata)*$repeat,
    "Data compresses smaller"
  );
 
  cmp_ok(
    $d->decompress($compdata), 'eq', $testdata x $repeat,
    'Data decompresses unchanged'
  );
  
};


done_testing();
