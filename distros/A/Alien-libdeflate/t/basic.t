use strict;
use warnings;

use Test::More;
use Test::Alien;
use Alien::libdeflate;

alien_ok 'Alien::libdeflate';

diag "Version Info";
diag join "\t", qw{Mod Lib};
diag join "\t", $Alien::libdeflate::VERSION, Alien::libdeflate->version;

SKIP: {
  skip "system install", 6 if Alien::libdeflate->install_type eq 'system';

  run_ok(['libdeflate-gzip', '-h'])
    ->success
    ->out_like(qr/^usage:\s+libdeflate-gzip(\.exe)?\s/mi);

  run_ok(['libdeflate-gunzip', '-h'])
    ->success
    ->out_like(qr/^usage:\s+libdeflate-gunzip(\.exe)?\s/mi);
}

done_testing;
