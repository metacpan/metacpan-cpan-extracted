use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::SWIG4;

alien_diag 'Alien::SWIG4';
alien_ok 'Alien::SWIG4';

run_ok([ qw(swig -version) ])
   ->success
   ->out_like(qr/SWIG Version ([0-9\.]+)/);

done_testing;
