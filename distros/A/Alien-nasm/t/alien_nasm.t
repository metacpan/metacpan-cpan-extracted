use Test2::V0 -no_srand => 1;
use Test::Alien 0.11;
use Alien::nasm ();

alien_ok 'Alien::nasm';

run_ok(['nasm', '-v'])
  ->success
  ->out_like(qr/NASM version/)
  ->note;

run_ok(['ndisasm', '-v'])
  ->success
  ->err_like(qr/NDISASM version/)
  ->note;

done_testing;
