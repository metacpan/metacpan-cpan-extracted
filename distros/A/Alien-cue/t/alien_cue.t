use Test2::V0 -no_srand => 1;
use Alien::cue;
use Test::Alien;

alien_ok 'Alien::cue';
run_ok(['cue', 'version'])
  ->note;

done_testing;


