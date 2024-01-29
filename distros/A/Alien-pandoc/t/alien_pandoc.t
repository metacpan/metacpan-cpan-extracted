use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::pandoc;

alien_diag 'Alien::pandoc';
alien_ok 'Alien::pandoc';

run_ok([ 'pandoc', '--version' ])
  ->success
  ->out_like(qr/^pandoc(?:\.exe)? ([0-9\.]+)/i);

done_testing;
