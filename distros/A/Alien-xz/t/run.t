use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::xz;

alien_ok 'Alien::xz';

run_ok(['xz', '--version'])
  ->success
  ->out_like(qr{XZ Utils})
  ->note;

done_testing;
