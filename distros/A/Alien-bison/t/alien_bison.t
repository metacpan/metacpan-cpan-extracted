use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::bison;

alien_ok 'Alien::bison';
my $run = run_ok(['bison', '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;

done_testing;
