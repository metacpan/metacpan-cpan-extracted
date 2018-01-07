use Test::More;
use Test::Alien;
use Alien::SLOCCount;
 
alien_ok 'Alien::SLOCCount';
 
run_ok(['sloccount', '--version'])
  ->success
  ->out_like(qr/\d+\.\d+/)
  ->note;
 
done_testing;
