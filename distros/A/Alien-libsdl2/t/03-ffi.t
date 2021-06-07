use Test2::V0;
use Test::Alien 1.90;
use Alien::libsdl2;
#
#skip_all 'requires a shared object or DLL'
#    unless Alien::libsdl2->dynamic_libs;
#
alien_ok 'Alien::libsdl2';
ffi_ok { api => 1, symbols => ['SDL_Init'] }, with_subtest {
    my ($ffi) = @_;
    my $init = $ffi->function( SDL_Init => ['uint32'] => 'int' )->call(0);
    ok !$init, 'Init(...) returns okay';
};
#
done_testing;
