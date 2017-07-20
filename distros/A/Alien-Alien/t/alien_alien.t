use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Alien;

alien_ok 'Alien::Alien';

my $run = run_ok(['alien', '--version'])
  ->success
  ->note;

if($run->exit)
{ $run->diag }
else
{ $run->note }

done_testing;
