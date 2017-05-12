use Test2::Bundle::Extended;
use Test::Alien;
use Acme::Alien::DontPanic;

alien_ok 'Acme::Alien::DontPanic';

run_ok('dontpanic')
  ->success
  ->out_like(qr{the answer to life the universe and everything is 42})
  ->note;

done_testing;
