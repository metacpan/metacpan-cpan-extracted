use Test2::V0 -no_srand => 1;
use Alien::pkgconf;

is( Alien::pkgconf->alien_helper->{pkgconf}->(), 'pkgconf', 'helper' );

done_testing;


