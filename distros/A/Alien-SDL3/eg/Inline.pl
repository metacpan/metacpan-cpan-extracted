use v5.40;
use blib;
use Alien::SDL3;
use Config;
use Inline ();    # Requires Inline::C

# Drive the SDL3 core library from C via Inline::C, using the compiler and linker flags that
# Alien::SDL3 reports for the primary (libsdl3) package.
my $sdl3 = Alien::SDL3->new;

# Install on first run if the dist isn't built yet (no ConfigData)
$sdl3->install unless $sdl3->ffi_lib;
my $incs = $sdl3->cflags;    # -I<include dir>
my $libs = $sdl3->libs;      # -L<link dir> -lSDL3

# SDL3 loads its DLL at runtime, so put the library's directory on PATH.
my $lib_dir = ( $sdl3->libpath // '' );
$lib_dir =~ s{[\\/][^\\/]*$}{};    # dirname of the shared lib
local $ENV{PATH} = join( $Config{path_sep}, $lib_dir, $ENV{PATH} );

# The precompiled libsdl3 package ships a shared lib but only a minimal header, so we declare the
# one symbol we call and rely on Inline::C to link it.
Inline->bind(
    'C', <<~'C',
    #include <stdio.h>

    /* const char * SDL_GetRevision(void); */
    extern const char * SDL_GetRevision();

    const char* sdl3_revision( ) {
        return SDL_GetRevision();
    }
    C
    INC  => $incs,
    LIBS => $libs
);
say 'Inline::C SDL3 revision: ' . sdl3_revision();

# Inline produced a real .so/.dll of its own; the flags came from the Alien.
say 'Linked SDL3 from:       ' . ( $sdl3->libpath // '(none)' );
