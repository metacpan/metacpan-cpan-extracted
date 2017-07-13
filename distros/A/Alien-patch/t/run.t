use Test2::V0;
use Test::Alien;
use Alien::patch ();

alien_ok 'Alien::patch';
run_ok(['patch', '--version'])
  ->success
  ->note;

done_testing;
