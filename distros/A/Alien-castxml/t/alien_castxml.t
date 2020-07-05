use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::castxml;

alien_ok 'Alien::castxml';

run_ok( ['castxml', '--version'] )
  ->success
  ->out_like(qr/castxml version/);

done_testing;


