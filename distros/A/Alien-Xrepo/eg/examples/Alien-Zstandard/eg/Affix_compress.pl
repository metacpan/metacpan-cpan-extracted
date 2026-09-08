use v5.40;
use Affix;
use Alien::Zstandard;
$|++;
my $zstd = Alien::Zstandard->new;

# Runtime resolution is lazy: a build-served snapshot or an xrepo store hit
# settles the package on demand; otherwise ffi_lib stays undef.
my $lib = $zstd->ffi_lib;
die "Could not find Zstd library path" unless $lib;
say "Loaded Zstd from: $lib";

# size_t ZSTD_compressBound(size_t srcSize);
affix $lib, 'ZSTD_compressBound', [Size_t] => Size_t;

# size_t ZSTD_compress(void* dst, size_t dstCapacity, const void* src, size_t srcSize, int compressionLevel);
affix $lib, 'ZSTD_compress', [ Pointer [Void], Size_t, String, Size_t, Int ] => Size_t;

# size_t ZSTD_isError(size_t code);
affix $lib, 'ZSTD_isError', [Size_t] => UInt;
my $data     = 'Hello, xmake and xrepo! ' x 10;    # Data to compress
my $data_len = length $data;

# Calculate max buffer size needed
my $bound = ZSTD_compressBound($data_len);

# Allocate a buffer for the compressed data
my $compressed_buffer = "\0" x $bound;

# Compress it
my $result_size = ZSTD_compress(
    $compressed_buffer, $bound, $data, $data_len, 1    # Compression level
);
die 'Zstd compression failed!' if ZSTD_isError($result_size);
say "Original Size:   $data_len bytes";
say "Compressed Size: $result_size bytes";

#~ https://facebook.github.io/zstd/doc/api_manual_latest.html#Chapter1
