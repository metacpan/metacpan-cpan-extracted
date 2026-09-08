use v5.40;
use FFI::Platypus 2.00;
use Alien::Zstandard;

# Instantiate the Alien module
my $alien = Alien::Zstandard->new;

# Runtime resolution is lazy: a build-served snapshot or an xrepo store hit
# settles the package on demand; otherwise ffi_lib stays undef.
# Initialize Platypus using api version 2
my $lib_path = $alien->ffi_lib;
die "Could not find Zstd library path" unless $lib_path;
my $ffi = FFI::Platypus->new(
    api => 2,
    lib => [$lib_path],    # Feed it the dynamic library
);
say "Loaded Zstd from: " . $lib_path;

# Attach the function to Perl space
# unsigned ZSTD_versionNumber(void);
$ffi->attach( 'ZSTD_versionNumber' => [] => 'unsigned int' );

# Call it!
my $version_int = ZSTD_versionNumber();

# Formatting the version number
my $major = int( $version_int / 10000 );
my $minor = int( ( $version_int % 10000 ) / 100 );
my $patch = $version_int % 100;
say "Platypus Zstd Version: v$major.$minor.$patch ($version_int)";
