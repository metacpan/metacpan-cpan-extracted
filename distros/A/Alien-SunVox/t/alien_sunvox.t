use Test2::V0;
use Test::Alien;
use Alien::SunVox;

alien_ok 'Alien::SunVox';
ffi_ok { symbols => [ 'sv_init' ], api => 1 };

done_testing;

