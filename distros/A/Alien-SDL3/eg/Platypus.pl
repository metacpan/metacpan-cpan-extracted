use v5.40;
use blib;
use FFI::Platypus 2.00;
use Alien::SDL3;

# Bind the SDL3 core library (the primary package) with FFI::Platypus.
my $sdl3 = Alien::SDL3->new;

# Install on first run if the dist isn't built yet (no ConfigData)
$sdl3->install unless $sdl3->ffi_lib;
my $lib_path = $sdl3->ffi_lib;
die 'Could not find SDL3 library path' unless $lib_path;
my $ffi = FFI::Platypus->new( api => 2, lib => [$lib_path], );
say 'Loaded SDL3 from: ' . $lib_path;

# const char * SDL_GetRevision(void);
$ffi->attach( 'SDL_GetRevision' => [] => 'string' );
say 'Platypus SDL3 revision: ' . SDL_GetRevision();

# The family is exposed through alt(). Pull the include dir for SDL3_ttf.
my $ttf = $sdl3->alt('libsdl3_ttf');
say 'SDL3_ttf include:    ' . ( $ttf->cflags // '' );
