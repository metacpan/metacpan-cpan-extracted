use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::raylib5;

alien_ok 'Alien::raylib5';

diag 'LIBS: ' . Alien::raylib5->libs;
ok( Alien::raylib5->libs ne '', 'Alien::raylib5->libs not empty' );

done_testing;
