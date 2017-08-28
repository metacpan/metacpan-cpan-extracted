#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test2::V0;
use Test::Alien;
use Alien::XGBoost;

alien_ok 'Alien::XGBoost';

# XGBoost C API lacks XGBVersion o similar
ffi_ok { symbols => [qw(XGBGetLastError XGDMatrixCreateFromMat)] }, with_subtest {
    my ($ffi) = @_;
    my $create_from_matrix =
      $ffi->function( XGDMatrixCreateFromMat => [qw(float[] uint64 uint64 float opaque*)] => 'int' );
    my $matrix = 0;
    my $return_code = $create_from_matrix->call( [ 1, 1 ], 1, 2, "NaN", \$matrix );
    like 0, $return_code;
};

done_testing;
