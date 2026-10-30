use v5.40;
use Affix;

# Load a Library
my $lib = load_library(libm);    # libm.so / msvcrt.dll

# Bind a Function
#    double pow(double x, double y);
affix $lib, 'pow', [ Double, Double ] => Double;

# Call it
say pow( 2.0, 10.0 );    # 1024

# Allocate 1KiB of raw memory
my $ptr = Affix::malloc(1024);

# Write raw data to the pointer
Affix::memcpy( $ptr, 'test', 4 );

# Poiner arithmetic creates a new reference (doesn't modify original)
my $offset_ptr = Affix::ptr_add( $ptr, 12 );
Affix::memcpy( $offset_ptr, 'test', 4 );

# Inspect memory with a hex dump to STDOUT
Affix::dump( $ptr, 32 );

# Release the memory
Affix::free($ptr);
