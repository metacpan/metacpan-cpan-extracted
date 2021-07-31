use Test2::V0 -no_srand => 1;
use Alien::GSL;
use Test::Alien::Diag qw( alien_diag );

alien_diag 'Alien::GSL';
ok 1;

done_testing;
