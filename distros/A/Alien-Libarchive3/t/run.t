use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Libarchive3;

skip_all 'only tested on share install'
  unless Alien::Libarchive3->install_type eq 'share';

alien_ok 'Alien::Libarchive3';

run_ok(['bsdtar', '--version'])
  ->success
  ->note;

done_testing;
