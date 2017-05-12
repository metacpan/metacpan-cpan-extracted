use Test2::Bundle::Extended;
use Test::Alien;
use Alien::patch ();

alien_ok 'Alien::patch';
run_ok(['patch', '--version'])
  ->success
  ->note;

done_testing;
