use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Nodejs;

alien_diag 'Alien::Nodejs';
alien_ok 'Alien::Nodejs';

 run_ok([ qw(node --version) ])
   ->success
   ->out_like(qr/^v([0-9\.]+)$/);

done_testing;
