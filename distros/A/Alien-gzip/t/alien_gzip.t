use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::gzip;

alien_ok 'Alien::gzip';

run_ok(['gzip', '--version'])
  ->success
  ->note;

done_testing;
