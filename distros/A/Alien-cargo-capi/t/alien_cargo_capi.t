use Test2::V0 -no_srand => 1;
use Alien::cargo::capi;
use Test::Alien;

alien_ok 'Alien::cargo::capi';

run_ok(['cargo','capi','build','--help'])
  ->success
  ->note;

done_testing;


