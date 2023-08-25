# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::libgs1encoders;

alien_ok 'Alien::libgs1encoders';

ffi_ok  { symbols => [ 'gs1_encoder_getVersion' ] }, with_subtest {
  my($ffi) = @_;
  my $gs1_get_version_string = $ffi->function('gs1_encoder_getVersion' => [] => 'string');
  ok $gs1_get_version_string->(), "has a version yo";
  note "gs1_get_version_string = ", $gs1_get_version_string->();
};

done_testing;
