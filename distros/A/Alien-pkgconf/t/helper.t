use Test2::Bundle::Extended;
use Alien::pkgconf;

is( Alien::pkgconf->alien_helper->{pkgconf}->(), 'pkgconf', 'helper' );

done_testing;


