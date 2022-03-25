use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::7zip;

alien_diag 'Alien::7zip';
diag "Alien::7zip {style} : ", Alien::7zip->runtime_prop->{'style'};
alien_ok 'Alien::7zip';

run_ok( Alien::7zip->exe )
  ->success
  ->out_like(qr/7-Zip (?:\Q(z) \E)?([0-9\.]+)/,);

done_testing;
