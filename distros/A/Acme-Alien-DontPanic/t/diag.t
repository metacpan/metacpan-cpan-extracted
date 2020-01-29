use Test2::V0;
use Test::Alien::Diag qw( alien_diag );
use Acme::Alien::DontPanic;

alien_diag 'Acme::Alien::DontPanic';

ok 1;

done_testing;
