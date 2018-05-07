use strict;
use warnings;

use Test::More;
use Test::Alien;
use Alien::libdeflate;

alien_ok 'Alien::libdeflate';

SKIP: {
  skip "system install", 9 if Alien::libdeflate->install_type eq 'system';

  run_ok(['gzip', '-h'])
    ->success
    ->out_like(qr/^usage:\s+gzip\s/mi);

  run_ok(['gunzip', '-h'])
    ->success
    ->out_like(qr/^usage:\s+gunzip\s/mi);

  run_ok(['checksum', '-h'])
    ->success
    ->out_like(qr/^usage:\s+checksum\s/mi);
}

done_testing;
