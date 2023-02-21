use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Go;

alien_diag 'Alien::Go';
alien_ok 'Alien::Go';

 run_ok([ qw(go version) ])
   ->success
   ->out_like(qr/^go version go([0-9\.]+)\b/);

done_testing;
