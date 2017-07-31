use Test2::V0;
use Test::Alien;
use Acme::Alien::DontPanic2;

alien_ok 'Acme::Alien::DontPanic2';

run_ok('dontpanic')
  ->success
  ->out_like(qr{the answer to life the universe and everything is 42})
  ->note;

done_testing;
