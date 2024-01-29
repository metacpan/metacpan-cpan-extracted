use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::hdt_java;

alien_diag 'Alien::hdt_java';
alien_ok 'Alien::hdt_java';

my $rdf2hdt = $^O ne 'MSWin32' ? 'rdf2hdt.sh' : 'rdf2hdt.bat';
run_ok([ $rdf2hdt, '-version' ])
  ->success
  ->out_like(qr/v([0-9.]+)/);

done_testing;
