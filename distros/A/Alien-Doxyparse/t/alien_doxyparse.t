use Test::More;
use Test::Alien;
use Alien::Doxyparse;
 
alien_ok 'Alien::Doxyparse';
 
run_ok(['doxyparse', '--version'])
  ->success
  ->out_like(qr/\d+\.\d+/)
  ->note;
 
done_testing;
