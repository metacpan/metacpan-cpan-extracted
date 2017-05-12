use Test2::Bundle::Extended;
use Test::Alien;
use Alien::flex;
use Env qw( @PATH );

alien_ok 'Alien::flex';

#diag "";
#diag "";
#diag "";
#diag "PATH:";
#diag "  - $_" for @PATH;
#diag "";
#diag "";
#diag "";

my $run = run_ok(['flex', '--version'])
  ->exit_is(0);

$run->success ? $run->note : $run->diag;
  
done_testing;
