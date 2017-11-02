use Test2::V0;
use Test::Alien;
use Alien::premake5;

alien_ok 'Alien::premake5';

my $run = run_ok([ Alien::premake5->exe, '--version' ])->exit_is(0);
$run->success ? $run->note : $run->diag;

done_testing;
