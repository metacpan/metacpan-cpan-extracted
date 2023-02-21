use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Deno;

alien_diag 'Alien::Deno';
alien_ok 'Alien::Deno';

run_ok([ qw(deno --version) ])
  ->success
  ->out_like(qr/^deno ([0-9\.]+)/);

done_testing;
