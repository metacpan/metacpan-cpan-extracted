use Test2::V0;
use Test::Alien;
use Alien::m4;

alien_ok 'Alien::m4';
my $run = run_ok([Alien::m4->exe, '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;
  
done_testing;
