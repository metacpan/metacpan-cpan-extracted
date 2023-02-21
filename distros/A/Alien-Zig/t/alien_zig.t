use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Zig;

alien_diag 'Alien::Zig';
alien_ok 'Alien::Zig';

 run_ok([ qw(zig version) ])
   ->success
   ->out_like(qr/^([0-9\.]+)(-.*)?$/);

done_testing;
