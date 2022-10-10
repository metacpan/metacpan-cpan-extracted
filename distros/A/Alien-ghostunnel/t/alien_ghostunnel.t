use Test2::V0 -no_srand => 1;
use Alien::ghostunnel;
use File::Which qw( which );
use Test::Alien;

alien_ok 'Alien::ghostunnel';

run_ok(['ghostunnel', '--version'])
  ->success;

diag '';
diag '';
diag '';
diag "exe = ", which('ghostunnel');
diag '';
diag '';

done_testing;


