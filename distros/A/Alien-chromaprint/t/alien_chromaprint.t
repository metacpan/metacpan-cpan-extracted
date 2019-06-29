use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::chromaprint;

alien_ok 'Alien::chromaprint';

diag '';
diag '';
diag '';
diag "cflags = ", Alien::chromaprint->cflags;
diag "libs   = ", Alien::chromaprint->libs;
diag "dll    = ", $_ for Alien::chromaprint->dynamic_libs;
diag '';
diag '';

done_testing
