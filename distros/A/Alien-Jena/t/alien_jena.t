use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Jena;

alien_diag 'Alien::Jena';
alien_ok 'Alien::Jena';

my $jena = $^O ne 'MSWin32' ? 'jena' : 'jena.bat';
run_ok([ $jena ])
  ->success
  ->out_like(qr/Jena version\s+:\s+([0-9\.]+)/);

done_testing;
