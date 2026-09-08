use v5.40;
use blib;
use Alien::Xrepo;
use Path::Tiny;
use Config;
use Inline ();    # Requires Inline::C

# Bind TWO libraries (libpng and zlib) into a single XS function with Inline::C.
# Install both (they land in the same store), merge their include and link
# directories, and hand the combined list to Inline::C.
my $repo = Alien::Xrepo->new();
my $png  = $repo->install('libpng') or die 'libpng install failed';
my $zlib = $repo->install('zlib')   or die 'zlib install failed';
say 'libpng: ' . $png->libpath;
say 'zlib:   ' . $zlib->libpath;
my @png_bins  = $png->bin_dir;
my @zlib_bins = $zlib->bin_dir;

# The compiled XS loads png.dll/libpng.so at runtime, which needs both native
# "bin" dirs on PATH.
local $ENV{PATH} = join( $Config{path_sep}, @png_bins, @zlib_bins, $ENV{PATH} );
my $incs = join ' ', map {"-I$_"} @{ $png->includedirs }, @{ $zlib->includedirs };
my $libs = join ' ', map {"-L$_"} ( @{ $png->linkdirs }, @{ $zlib->linkdirs } ), map {"-l$_"} ( @{ $png->links }, @{ $zlib->links } );
Inline->bind(
    'C', <<~'C',
    #include <stdio.h>
    #include <png.h>
    #include <zlib.h>

    const char* xrepo_versions( ) {
        static char buf[128];
        snprintf(buf, sizeof buf, "libpng %s / zlib %s", PNG_LIBPNG_VER_STRING, ZLIB_VERSION);
        return buf;
    }
    C
    INC  => $incs,
    LIBS => $libs
);
say xrepo_versions();
