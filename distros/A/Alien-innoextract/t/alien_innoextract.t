use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::innoextract;

alien_diag 'Alien::innoextract';
alien_ok 'Alien::innoextract';

run_ok([ Alien::innoextract->exe, qw(--version) ])
  ->success
  ->out_like(qr/^innoextract ([0-9\.]+)/);

done_testing;
