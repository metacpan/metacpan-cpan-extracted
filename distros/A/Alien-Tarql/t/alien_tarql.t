use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Tarql;

alien_diag 'Alien::Tarql';
alien_ok 'Alien::Tarql';

my $tarql = $^O ne 'MSWin32' ? 'tarql' : 'tarql.bat';
run_ok([ $tarql, '--version' ])
  ->success
  ->out_like(qr/tarql:\s+VERSION:\s+([0-9\.]+)/);

done_testing;
