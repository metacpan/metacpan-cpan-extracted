use Test2::Bundle::Extended;
use Test::Alien;
use Alien::xz;

alien_ok 'Alien::xz';

run_ok(['xz', '--version'])
  ->success
  ->out_like(qr{XZ Utils})
  ->note;

done_testing;
