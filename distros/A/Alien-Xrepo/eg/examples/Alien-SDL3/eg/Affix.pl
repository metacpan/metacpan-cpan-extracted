use v5.40;
use Affix;
use Alien::SDL3;

# Bind the SDL3 core library (the primary package) with Affix.
my $sdl3 = Alien::SDL3->new;

# Runtime resolution is lazy: a build-served snapshot or an xrepo store hit
# settles the package on demand; otherwise ffi_lib stays undef.
my $lib_path = $sdl3->ffi_lib;
die 'Could not find SDL3 library path' unless $lib_path;
say 'Loaded SDL3 from: ' . $lib_path;

# const char * SDL_GetRevision(void);
affix $lib_path, 'SDL_GetRevision', [] => String;
say 'Affix SDL3 revision: ' . SDL_GetRevision();

# The family is exposed through alt(). Show a sibling package is on disk too.
my $ttf = $sdl3->alt('libsdl3_ttf');
say 'SDL3_ttf lib:      ' . ( $ttf->libpath // '(none)' );
