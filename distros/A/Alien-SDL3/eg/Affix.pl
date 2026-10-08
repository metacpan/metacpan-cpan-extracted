use v5.40;
use blib;
use Affix;
use Alien::SDL3;

# Bind the SDL3 core library (the primary package) with Affix.
my $sdl3 = Alien::SDL3->new;

# Install on first run if the dist isn't built yet (no ConfigData)
$sdl3->install unless $sdl3->ffi_lib;
my $lib_path = $sdl3->ffi_lib;
die 'Could not find SDL3 library path' unless $lib_path;
say 'Loaded SDL3 from: ' . $lib_path;

# const char * SDL_GetRevision(void);
affix $lib_path, 'SDL_GetRevision', [] => String;
say 'Affix SDL3 revision: ' . SDL_GetRevision();

# The family is exposed through alt(). Show a sibling package is on disk too.
my $ttf = $sdl3->alt('libsdl3_ttf');
say 'SDL3_ttf lib:      ' . ( $ttf->libpath // '(none)' );
