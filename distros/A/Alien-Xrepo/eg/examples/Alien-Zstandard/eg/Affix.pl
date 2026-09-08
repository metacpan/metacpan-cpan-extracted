use v5.40;
use Affix;
use Alien::Zstandard;

# Instantiate the Alien module
my $zstd_alien = Alien::Zstandard->new;

# Runtime resolution is lazy: a build-served snapshot or an xrepo store hit
# settles the package on demand; otherwise ffi_lib stays undef.
# Get the path to the dynamic library (.so, .dll, or .dylib)
my $lib_path = $zstd_alien->ffi_lib;
die 'Could not find Zstd library path' unless $lib_path;
say "Loaded Zstd from: $lib_path";

# Bind the C function to Perl space
# unsigned ZSTD_versionNumber(void);
affix $lib_path, 'ZSTD_versionNumber', [] => UInt;

# Call it natively!
my $version_int = ZSTD_versionNumber();

# Formatting the version number (format is: MAJOR * 10000 + MINOR * 100 + PATCH)
my $major = int( $version_int / 10000 );
my $minor = int( ( $version_int % 10000 ) / 100 );
my $patch = $version_int % 100;
say "Affix Zstd Version: v$major.$minor.$patch ($version_int)";
