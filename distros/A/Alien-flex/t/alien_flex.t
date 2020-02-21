use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::Diag;
use Alien::flex;
use Env qw( @PATH );

alien_ok 'Alien::flex';

alien_diag 'Alien::flex';

my $run = run_ok(['flex', '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;

done_testing;
