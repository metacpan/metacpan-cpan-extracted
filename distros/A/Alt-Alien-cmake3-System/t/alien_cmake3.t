use Test2::V0 -no_srand => 1;
use Test::Alien 0.92;
use Alien::cmake3;

alien_ok 'Alien::cmake3';

run_ok(['cmake', '--version'])
  ->exit_is(0)
  ->out_like(qr/cmake version 3\.([0-9\.])+/)
  ->note;

helper_ok 'cmake3';

done_testing
