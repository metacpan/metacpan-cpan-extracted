use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Meson;

alien_diag 'Alien::Meson';
alien_ok 'Alien::Meson';

run_ok([ Alien::Meson->exe, qw(--version) ])
  ->success
  ->out_like(qr/[0-9\.]+/);

done_testing;
