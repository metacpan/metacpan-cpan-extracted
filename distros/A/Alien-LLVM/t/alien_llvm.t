use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::LLVM;

alien_diag 'Alien::LLVM';
alien_ok 'Alien::LLVM';

# run_ok([ ... ])
#   ->success
#   ->out_like(qr/ ... /);

done_testing;
