#!perl

use strict; use warnings;
use Crypt::Affine;
use Test::More tests => 1;

my $affine = Crypt::Affine->new(m => 5, r => 8);
is($affine->decrypt('mLLazG waJVGT'), 'affine cipher');