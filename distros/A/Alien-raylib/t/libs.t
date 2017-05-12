use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::raylib;

alien_ok 'Alien::raylib';

diag 'LIBS: ' . Alien::raylib->libs;
ok(Alien::raylib->libs ne '', 'Alien::raylib->libs not empty');

done_testing;
