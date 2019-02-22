use Test2::V0 -no_srand => 1;
use Alien::unzip;
use Test::Alien;

alien_ok 'Alien::unzip';

run_ok(['unzip', '-v'])
  ->success
  ->out_like(qr/UnZip.*Info-ZIP/)
  ->note;

done_testing
