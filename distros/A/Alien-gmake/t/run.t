use Test2::Bundle::Extended;
use Test::Alien;
use Alien::gmake ();

alien_ok 'Alien::gmake';
my $run = run_ok([Alien::gmake->exe, '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;
  
done_testing;
