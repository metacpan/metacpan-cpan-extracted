use Test2::Bundle::Extended;
use Test::Alien;
use Alien::m4;

alien_ok 'Alien::m4';
my $run = run_ok(['m4', '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;
  
done_testing;
