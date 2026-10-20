use v5.40;
use blib;
use Test2::V0;
use Exotic::SDL3;
#
my $sdl3 = Exotic::SDL3->new;

# The package must actually be installed (a build-served snapshot or a store
# hit); otherwise there is nothing at all to exercise.
SKIP: {
    my $info = $sdl3->package_info;
    skip 'libsdl3 not installed; run the build first' => 1 unless $info;
    ok defined $sdl3->version, 'resolved package version is recorded';
}

# Load the installed shared libsdl3 and read its version with the first FFI
# backend that is installed (Affix, then FFI::Platypus). SDL3's SDL_GetVersion
# takes no arguments and returns the linked version code: major*10^6 +
# minor*10^3 + micro (3.4.12 -> 3004012). Neither installed, or the library
# resolved static (nothing to dlopen): skip.
SKIP: {
    my $info = $sdl3->package_info;
    skip 'package not installed, or resolved as a static archive with nothing to load' => 1 unless $info && $info->shared && $sdl3->ffi_lib;
    my $lib = $sdl3->ffi_lib;
    if ( eval { require Affix; Affix->import; 1 } ) {
        Affix::affix( $lib, 'SDL_GetVersion', [], Affix::Int() );
        my $code = SDL_GetVersion();
        my $ver  = sprintf '%d.%d.%d', ( $code / 1_000_000 ), ( $code / 1000 ) % 1000, $code % 1000;
        diag "Affix loaded $lib: SDL $ver (code $code)";
        like $ver, qr{^3\.\d+\.\d+$}, 'SDL_GetVersion reports an SDL3 version';
    }
    elsif ( eval { require FFI::Platypus; 1 } ) {
        my $ffi = FFI::Platypus->new( api => 2, lib => [$lib] );
        $ffi->attach( 'SDL_GetVersion' => [] => 'int' );
        my $code = SDL_GetVersion();
        my $ver  = sprintf '%d.%d.%d', ( $code / 1_000_000 ), ( $code / 1000 ) % 1000, $code % 1000;
        diag "FFI::Platypus loaded $lib: SDL $ver (code $code)";
        like $ver, qr{^3\.\d+\.\d+$}, 'SDL_GetVersion reports an SDL3 version';
    }
    else {
        skip 'neither Affix nor FFI::Platypus is installed' => 1;
    }
}
#
done_testing;
