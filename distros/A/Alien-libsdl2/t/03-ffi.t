use Test2::V0;
use Test::Alien 1.90;
use lib -d '../t' ? './lib' : 't/lib';
use Alien::libsdl2;
#
#skip_all 'requires a shared object or DLL'
#    unless Alien::libsdl2->dynamic_libs;
#
#  nasty hack
#$ENV{LD_LIBRARY_PATH}   = Alien::libsdl2->dist_dir . '/lib';
#$ENV{DYLD_LIBRARY_PATH} = Alien::libsdl2->dist_dir . '/lib';
#
diag( 'dist_dir: ' . Alien::libsdl2->dist_dir . '/lib' );
diag( 'libs: ' . Alien::libsdl2->libs );
diag( 'cflags: ' . Alien::libsdl2->cflags );
diag( 'cflags static: ' . Alien::libsdl2->cflags_static );
eval { diag( 'Dynamic libs: ' . join ':', Alien::libsdl2->dynamic_libs ); };
warn $@ if $@;
diag( 'bin dir: ' . join( ' ', Alien::libsdl2->bin_dir ) );
alien_ok 'Alien::libsdl2';
ffi_ok {
    api => 1, symbols => ['SDL_Init'], experimental => 2,
    lib => [ Alien::libsdl2->dynamic_libs ]
    },
    with_subtest {
    my ($ffi) = @_;
    my $init = $ffi->function( SDL_Init => ['uint32'] => 'int' )->call(0);
    ok !$init, 'Init(...) returns okay';
    };
#
done_testing;
