# 📦 Compression::Util

[![CPAN](https://img.shields.io/badge/CPAN-Compression%3A%3AUtil-blue)](https://metacpan.org/pod/Compression::Util)
[![Perl](https://img.shields.io/badge/Perl-39457E?logo=perl&logoColor=white)](https://www.perl.org/)

**Compression::Util** is a pure-Perl toolkit for experimenting with, composing, and implementing data-compression algorithms and formats. It exposes everything from individual bit/byte primitives and entropy coders to complete **BWT**, **LZ77/LZSS**, **LZW**, **DEFLATE**, **Bzip2**, **GZIP**, **ZLIB**, and **LZ4** pipelines.

> 🧠 **Design philosophy:** build compression pipelines from small, reusable pieces. Use a ready-made compressor when you want convenience, or combine low-level transforms and coders when you want complete control.

## ✨ Highlights

- 🌀 Burrows–Wheeler, Move-to-Front, Run-Length and delta transforms
- 🌳 Huffman and arithmetic coding, including adaptive arithmetic coding
- 🔤 Fibonacci, Elias gamma/omega, ABC and OBH integer coding
- 📦 LZ77/LZSS/LZW compression and symbolic variants for arbitrary integer symbols
- 🧰 BWT-based compression, plus Bzip2, GZIP, ZLIB, DEFLATE and LZ4 support
- 🔬 Low-level bit/byte I/O, checksums, alphabet handling and format primitives
- 🧩 Pipelines are composable: plug different entropy coders or LZ parsers into higher-level algorithms
- 🐪 Pure Perl — useful for portability, experimentation, education and algorithm research

## 📦 Installation

Install from CPAN with:

```bash
cpanm Compression::Util
```

Or install directly with your preferred CPAN client:

```bash
cpan Compression::Util
```

## 🗺️ Contents

- [⚡ Quick Start](#quick-start)
- [🧩 Overview](#overview)
- [🧭 Choosing the Right API](#choosing-the-right-api)
- [⚙️ Package Variables](#package-variables)
- [🚀 High-Level Functions](#high-level-functions)
- [🧱 Medium-Level Functions](#medium-level-functions)
- [🔬 Low-Level Functions](#low-level-functions)
- [💡 Examples](#examples)
- [📖 References](#references)
- [🔎 See Also](#see-also)

---

**Version:** `0.18`

<a id="quick-start"></a>

# ⚡ Quick Start

    use 5.036;
    use Getopt::Std       qw(getopts);
    use Compression::Util qw(:all);

    use constant {CHUNK_SIZE => 1 << 17};

    local $Compression::Util::VERBOSE = 0;

    getopts('d', \my %opts);

    sub compress ($fh, $out_fh) {
        while (read($fh, (my $chunk), CHUNK_SIZE)) {
            print $out_fh bwt_compress($chunk);
        }
    }

    sub decompress ($fh, $out_fh) {
        while (!eof($fh)) {
            print $out_fh bwt_decompress($fh);
        }
    }

    $opts{d} ? decompress(\*STDIN, \*STDOUT) : compress(\*STDIN, \*STDOUT);

A quicker taste, compressing and decompressing a string in memory with a real, industry-standard container format:

    use 5.036;
    use Compression::Util qw(gzip_compress gzip_decompress);

    my $data       = "the quick brown fox jumps over the lazy dog " x 20;
    my $compressed = gzip_compress($data);
    my $round_trip = gzip_decompress($compressed);

    $round_trip eq $data or die "round-trip failed";

    printf("%d -> %d bytes (%.1f%%)\n",
        length($data), length($compressed), 100 * length($compressed) / length($data));

<a id="overview"></a>

# 🧩 Overview

**Compression::Util** is a function-based module, implementing various techniques used in data compression, such as:

- Burrows-Wheeler transform
- Move-to-front transform
- Huffman Coding
- Arithmetic Coding (in fixed bits, static and adaptive)
- Run-length encoding
- Fibonacci coding
- Elias gamma/omega coding
- Delta coding
- BWT-based (de)compression
- LZ77/LZSS (de)compression
- LZW (de)compression
- Bzip2 (de)compression
- GZIP (de)compression
- ZLIB (de)compression
- LZ4 (de)compression

Nothing is exported by default: every function below is available on demand, either individually or via the `:all` tag (see ["EXPORT"](export)). This makes it straightforward to build compressors ranging from a couple of lines that reuse a full pipeline (["HIGH-LEVEL FUNCTIONS"](high-level-functions)), down to hand-rolled formats assembled from individual transforms and entropy coders (["LOW-LEVEL FUNCTIONS"](low-level-functions) and ["MEDIUM-LEVEL FUNCTIONS"](medium-level-functions)).

The provided techniques can be easily combined in various ways to create powerful compressors, such as the Bzip2 compressor, which is a pipeline of the following methods:

    1. Run-length encoding (RLE4)
    2. Burrows-Wheeler transform (BWT)
    3. Move-to-front transform (MTF)
    4. Zero run-length encoding (ZRLE)
    5. Huffman coding

A simple BWT-based compression method (similar to Bzip2) is provided by the function `bwt_compress()`, which can be explicitly implemented as:

    use 5.036;
    use Compression::Util qw(:all);

    my $data = do { open my $fh, '<:raw', $^X; local $/; <$fh> };
    my $rle4 = rle4_encode(string2symbols($data));
    my ($bwt, $idx) = bwt_encode(symbols2string($rle4));

    my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
    my $rle = zrle_encode($mtf);

    my $enc = pack('N', $idx)
            . encode_alphabet($alphabet)
            . create_huffman_entry($rle);

    say "Original size  : ", length($data);
    say "Compressed size: ", length($enc);

    # Decompress the result
    bwt_decompress($enc) eq $data or die "decompression error";

<a id="choosing-the-right-api"></a>

## 🧭 Choosing the Right API

If you just want to shrink some data and don't care how, reach for a ["HIGH-LEVEL FUNCTIONS"](high-level-functions) pair such as `gzip_compress()` / `gzip_decompress()` (a real, interoperable GZIP stream) or `bwt_compress()` / `bwt_decompress()` (a lighter, module-specific container). If you want to design your own container format out of individual building blocks -- for example, applying Huffman coding to the output of your own transform -- use the ["MEDIUM-LEVEL FUNCTIONS"](medium-level-functions). If you are implementing a specific bit-exact format (such as DEFLATE) or need direct access to bit/byte I/O, transforms, or entropy coders in isolation, use the ["LOW-LEVEL FUNCTIONS"](low-level-functions).

## 📚 Terminology

### bit

A bit value is either `1` or `0`.

### bitstring

A bitstring is a string containing only the characters `1` and `0` (not packed bits). Many low-level encoders return a bitstring; pass it through `pack('B*', $bitstring)` to get a packed binary string, and `unpack('B*', $string)` to go the other way.

### byte

A byte value is an integer between `0` and `255`, inclusive.

### string

A string means a binary (non-UTF\*) string. Any file-handle used to read or write such a string must have its encoding layer set to `:raw` (see ["filehandle"](#filehandle) below).

### symbols

An array of symbols means an array-ref of non-negative integer values. Symbols are not restricted to the `[0, 255]` byte range unless a specific function says otherwise (for example `encode_alphabet_256()`); this is what makes the "symbolic" variants of many functions (`bwt_encode_symbolic()`, `lzss_encode_symbolic()`, `lz77_encode_symbolic()`, etc.) useful for compressing sequences of large integers rather than bytes, such as intermediate output from another codec.

### alphabet

An alphabet is a sorted array-ref of the distinct symbols that occur in a sequence, with no repeats. Several functions (such as `mtf_encode()` and `adaptive_ac_encode()`) return or accept an alphabet alongside the encoded data.

### filehandle

A filehandle is denoted by `$fh`. The encoding of file-handles must be set to `:raw` (i.e. `open(my $fh, '<:raw', $path)`), so that bytes are read and written without any character-encoding or line-ending translation.

### entropy coding sub

Many of the higher-level functions accept an optional code-ref parameter (commonly named `$entropy_sub`) that plugs in the final entropy-coding stage of a pipeline, letting you swap Huffman coding for Arithmetic Coding (or a custom coder) without re-implementing the surrounding pipeline. See ["create_huffman_entry"](#create_huffman_entry) and ["create_ac_entry"](#create_ac_entry) for the two coders built into this module, and ["Combining LZSS + MRL compression"](#combining-lzss--mrl-compression) for a usage example.

## 📝 Conventions

A few conventions apply consistently across the module and are worth knowing up front, rather than being repeated in every function's description:

- **String or symbols.** Functions documented as accepting `\@symbols` will also accept a plain string in its place (it is converted internally via `string2symbols()`). Functions with a `_symbolic` counterpart (e.g. `bwt_encode()` / `bwt_encode_symbolic()`) exist because the plain version is optimized for byte strings, while the `_symbolic` version works with arbitrary non-negative integers and has no upper bound on symbol values.

- **Filehandle or string, transparently.** Any decoder that takes `$fh` as its first argument will also accept a plain packed binary string; internally it opens an in-memory filehandle over the string (`open($fh2, '<:raw', \$string)`) and recurses. This means `lzss_decompress($string)` and `lzss_decompress($fh)` both work, and the two forms can be mixed freely when chaining decoders.

- **Streaming decompression.** Because decoders read only as much as they need from `$fh`, several compressed blocks can be concatenated back-to-back in a single file and decoded one at a time in a loop (see the ["SYNOPSIS"](synopsis)), without needing to record each block's length up front.

- **Package variables are dynamically scoped.** The `$LZ_*` tuning variables (["PACKAGE VARIABLES"](package-variables) below) are read at the time an LZ-family encoder runs. Use `local` to override them for the duration of a single call, so that concurrent or later calls elsewhere in your program are unaffected:

      {
          local $Compression::Util::LZ_MAX_CHAIN_LEN = 128;
          my $enc = lzss_compress($data);   # uses the higher chain length
      }
      # back to the default of 32 here

<a id="package-variables"></a>

# ⚙️ Package Variables

**Compression::Util** provides the following package variables:

    $Compression::Util::VERBOSE = 0;           # true to enable verbose/debug mode

    $Compression::Util::LZ_MIN_LEN = 4;        # minimum match length in LZ parsing
    $Compression::Util::LZ_MAX_LEN = 1 << 15;  # maximum match length in LZ parsing

    $Compression::Util::LZ_MAX_DIST = ~0;              # maximum back-reference distance allowed
    $Compression::Util::LZ_MAX_CHAIN_LEN = 32;         # how many recent positions to remember for each match in LZ parsing
    $Compression::Util::LZ_MAX_CHAIN_WIDTH = 1024;     # how many positions to store per matched prefix

These package variables can also be imported as:

    use Compression::Util qw(
        $LZ_MIN_LEN
        $LZ_MAX_LEN
        $LZ_MAX_DIST
        $LZ_MAX_CHAIN_LEN
        $LZ_MAX_CHAIN_WIDTH
    );

## 🔍 `$VERBOSE`

When set to a true value, many functions print diagnostic information (block sizes, header fields, checksums, and so on) to `STDERR`. Useful when debugging a hand-assembled pipeline or inspecting third-party GZIP/ZLIB/LZ4 streams being decoded.

By default, `$VERBOSE` is set to `0`.

## 🎚️ `$LZ_MIN_LEN`

Minimum length of a match in LZ parsing. The value must be an integer greater than or equal to `2`. Larger values will result in faster parsing, but lower compression ratio.

By default, `$LZ_MIN_LEN` is set to `4`.

**NOTE:** for `lzss_encode_fast()` is recommended to set `$LZ_MIN_LEN = 5`, which will result in slightly better compression ratio.

## 📏 `$LZ_MAX_LEN`

Maximum length of a match in LZ parsing. The value must be an integer greater than or equal to `0`.

By default, `$LZ_MAX_LEN` is set to `32768`.

**NOTE:** the functions `lz77_encode()` and `lzb_compress()` will ignore this value and will always use unlimited match lengths.

## ↔️ `$LZ_MAX_DIST`

Maximum back-reference distance allowed in LZ parsing. Smaller values will result in faster parsing, but lower compression ratio.

By default, the value is unlimited, meaning that arbitrarily large back-references will be generated.

**NOTE:** the function `lzb_compress()` will ignore this value and will always use the value `2**16 - 1` as the maximum back-reference distance.

## 🔗 `$LZ_MAX_CHAIN_LEN`

The value of `$LZ_MAX_CHAIN_LEN` controls the amount of recent positions to remember for each matched prefix. A larger value results in better compression, finding longer matches, at the expense of speed.

By default, `$LZ_MAX_CHAIN_LEN` is set to `32`.

**NOTE:** the function `lzss_encode_fast()` will ignore this value, always using a value of `1`.

## 🧱 `$LZ_MAX_CHAIN_WIDTH`

The value of `$LZ_MAX_CHAIN_WIDTH` controls the number of positions to store from each match. A larger value may result in better compression, finding longer matches, at the expense of speed.

By default, `$LZ_MAX_CHAIN_WIDTH` is set to `1024`.

**NOTE:** the function `lzss_encode_fast()` will ignore this value, always using a value of `1`.

## 🚀 Choosing an LZSS Encoder

The module ships three LZ-parsing engines with different speed/ratio trade-offs, all of which produce output consumable by the same `lzss_decode()` / `lzss_decode_symbolic()`:

    lzss_encode()             # best compression; honors all $LZ_* tuning variables
    lzss_encode_fast()        # faster, chain length fixed to 1; good with $LZ_MIN_LEN = 5

Any of these can be plugged into the higher-level compressors (`lz77_compress()`, `lzss_compress()`, `lzb_compress()`, `lz4_compress()`, `gzip_compress()`, `zlib_compress()`) via their optional `$lzss_encoding_sub` argument, so the trade-off can be tuned per call without touching the rest of the pipeline.

<a id="high-level-functions"></a>

# 🚀 High-Level Functions

Ready-made compressors and decompressors, each wrapping a full pipeline of transforms and an entropy coder. Start here unless you need to design your own format.

    create_huffman_entry(\@symbols)      # Create a Huffman Coding block
    decode_huffman_entry($fh)            # Decode a Huffman Coding block

    create_ac_entry(\@symbols)           # Create an Arithmetic Coding block
    decode_ac_entry($fh)                 # Decode an Arithmetic Coding block

    create_adaptive_ac_entry(\@symbols)  # Create an Adaptive Arithmetic Coding block
    decode_adaptive_ac_entry($fh)        # Decode an Adaptive Arithmetic Coding block

    mrl_compress($string)                # MRL compression (MTF+ZRLE+RLE4+Huffman coding)
    mrl_decompress($fh)                  # Inverse of the above method

    mrl_compress_symbolic(\@symbols)     # Symbolic MRL compression (MTF+ZRLE+RLE4+Huffman coding)
    mrl_decompress_symbolic($fh)         # Inverse of the above method

    bwt_compress($string)                # BWT-based compression (RLE4+BWT+MTF+ZRLE+Huffman coding)
    bwt_decompress($fh)                  # Inverse of the above method

    bwt_compress_symbolic(\@symbols)     # Symbolic BWT-based compression (RLE4+sBWT+MTF+ZRLE+Huffman coding)
    bwt_decompress_symbolic($fh)         # Inverse of the above method

    bzip2_compress($string)              # Compress a given string using the Bzip2 format
    bzip2_decompress($fh)                # Inverse of the above method

    gzip_compress($string)               # Compress a given string using the GZIP format
    gzip_decompress($fh)                 # Inverse of the above method

    zlib_compress($string)               # Compress a given string using the ZLIB format
    zlib_decompress($fh)                 # Inverse of the above method

    lzss_compress($string)               # LZSS + DEFLATE-like encoding of lengths and distances
    lzss_decompress($fh)                 # Inverse of the above method

    lzss_compress_symbolic(\@symbols)    # Symbolic LZSS + DEFLATE-like encoding of lengths and distances
    lzss_decompress_symbolic($fh)        # Inverse of the above method

    lz77_compress($string)               # LZ77 + Huffman coding of lengths and literals + OBH for distances
    lz77_decompress($fh)                 # Inverse of the above method

    lz77_compress_symbolic(\@symbols)    # Symbolic LZ77 + Huffman coding of lengths and literals + OBH for distances
    lz77_decompress_symbolic($fh)        # Inverse of the above method

    lzb_compress($string)                # LZSS compression, using a byte-aligned encoding method, similar to LZ4
    lzb_decompress($fh)                  # Inverse of the above method

    lzw_compress($string)                # LZW + abc_encode() compression
    lzw_decompress($fh)                  # Inverse of the above method

    lz4_compress($string)                # Compress a given string using the LZ4 frame format
    lz4_decompress($fh)                  # Inverse of the above method

<a id="medium-level-functions"></a>

# 🧱 Medium-Level Functions

Individual transforms and entropy coders, meant to be composed together into your own pipeline (as the ["HIGH-LEVEL FUNCTIONS"](high-level-functions) do internally).

    deltas(\@ints)                       # Computes the differences between integers
    accumulate(\@deltas)                 # Inverse of the above method

    delta_encode(\@ints)                 # Delta+RLE+Elias omega encoding of an array-ref of integers
    delta_decode($fh)                    # Inverse of the above method

    fibonacci_encode(\@symbols)          # Fibonacci coding of an array-ref of symbols
    fibonacci_decode($fh)                # Inverse of the above method

    elias_gamma_encode(\@symbols)        # Elias Gamma coding method of an array-ref of symbols
    elias_gamma_decode($fh)              # Inverse of the above method

    elias_omega_encode(\@symbols)        # Elias Omega coding method of an array-ref of symbols
    elias_omega_decode($fh)              # Inverse of the above method

    abc_encode(\@symbols)                # Adaptive Binary Concatenation method of an array-ref of symbols
    abc_decode($fh)                      # Inverse of the above method

    obh_encode(\@symbols)                # Offset bits + Huffman coding of an array-ref of symbols
    obh_decode($fh)                      # Inverse of the above method

    bwt_encode($string)                  # Burrows-Wheeler transform
    bwt_decode($bwt, $idx)               # Inverse of Burrows-Wheeler transform

    bwt_encode_symbolic(\@symbols)       # Burrows-Wheeler transform over an array-ref of symbols
    bwt_decode_symbolic(\@bwt, $idx)     # Inverse of symbolic Burrows-Wheeler transform

    mtf_encode(\@symbols)                # Move-to-front transform
    mtf_decode(\@mtf, \@alphabet)        # Inverse of the above method

    encode_alphabet(\@alphabet)          # Encode an alphabet of symbols into a binary string
    decode_alphabet($fh)                 # Inverse of the above method

    encode_alphabet_256(\@alphabet)      # Encode an alphabet of symbols (limited to [0..255]) into a binary string
    decode_alphabet_256($fh)             # Inverse of the above method

    frequencies(\@symbols)               # Returns a dictionary with symbol frequencies
    run_length(\@symbols, $max=undef)    # Run-length encoding, returning a 2D array-ref

    rle4_encode(\@symbols, $max=255)     # Run-length encoding with 4 or more consecutive characters
    rle4_decode(\@rle4)                  # Inverse of the above method

    zrle_encode(\@symbols)               # Run-length encoding of zeros
    zrle_decode(\@zrle)                  # Inverse of the above method

    ac_encode(\@symbols)                 # Arithmetic Coding applied on an array-ref of symbols
    ac_decode($bitstring, \%freq)        # Inverse of the above method

    adaptive_ac_encode(\@symbols)               # Adaptive Arithmetic Coding applied on an array-ref of symbols
    adaptive_ac_decode($bitstring, \@alphabet)  # Inverse of the above method

    lzw_encode($string)                  # LZW encoding of a given string
    lzw_decode(\@symbols)                # Inverse of the above method

<a id="low-level-functions"></a>

# 🔬 Low-Level Functions

Bit/byte I/O primitives, raw LZ parsing, Huffman table construction, and DEFLATE block handling. These are what the medium- and high-level functions are built from; reach for them when implementing a specific bit-exact format or when you need finer control than the higher tiers expose.

    crc32($string, $prev_crc = 0)        # Compute the CRC32 value of a given string
    adler32($string, $prev_adler = 1)    # Compute the Adler32 value of a given string

    read_bit($fh, \$buffer)              # Read one bit from file-handle (MSB)
    read_bit_lsb($fh, \$buffer)          # Read one bit from file-handle (LSB)

    read_bits($fh, $len)                 # Read `$len` bits from file-handle (MSB)
    read_bits_lsb($fh, $len)             # Read `$len` bits from file-handle (LSB)

    int2bits($symbol, $size)             # Convert an integer to bits of width `$size` (MSB)
    int2bits_lsb($symbol, $size)         # Convert an integer to bits of width `$size` (LSB)

    bits2int($fh, $size, \$buffer)       # Inverse of `int2bits()`
    bits2int_lsb($fh, $size, \$buffer)   # Inverse of `int2bits_lsb()`

    bytes2int($fh, $n)                   # Read `$n` bytes from file-handle as an integer (MSB)
    bytes2int_lsb($fh, $n)               # Read `$n` bytes from file-handle as an integer (LSB)

    int2bytes($symbol, $size)            # Convert an integer into `$size` bytes. (MSB)
    int2bytes_lsb($symbol, $size)        # Convert an integer into `$size` bytes. (LSB)

    string2symbols($string)              # Returns an array-ref of code points
    symbols2string(\@symbols)            # Returns a string, given an array-ref of code points

    read_null_terminated($fh)            # Read a binary string that ends with NULL ("\0")

    binary_vrl_encode($bitstring)        # Binary variable run-length encoding
    binary_vrl_decode($bitstring)        # Binary variable run-length decoding

    bwt_sort($string)                    # Burrows-Wheeler sorting
    bwt_sort_symbolic(\@symbols)         # Burrows-Wheeler sorting, applied on an array-ref of symbols

    huffman_encode(\@symbols, \%dict)    # Huffman encoding
    huffman_decode($bitstring, \%dict)   # Huffman decoding, given a string of bits

    huffman_from_freq(\%freq)            # Create Huffman dictionaries, given an hash-ref of frequencies
    huffman_from_symbols(\@symbols)      # Create Huffman dictionaries, given an array-ref of symbols
    huffman_from_code_lengths(\@lens)    # Create canonical Huffman codes, given an array-ref of code lengths

    make_deflate_tables($max_dist, $max_len) # Returns the DEFLATE tables for distance and length symbols
    find_deflate_index($value, \@table)      # Returns the index in a DEFLATE table, given a numerical value

    lzss_encode($string)                     # LZSS encoding into literals, distances and lengths
    lzss_encode_symbolic(\@symbols)          # LZSS encoding into literals, distances and lengths (symbolic)

    lzss_encode_fast($string)                # Fast-LZSS encoding into literals, distances and lengths
    lzss_encode_fast_symbolic(\@symbols)     # Fast-LZSS encoding into literals, distances and lengths (symbolic)

    lzss_decode(\@lits, \@dist, \@lens)          # Inverse of lzss_encode() and lzss_encode_fast()
    lzss_decode_symbolic(\@lits, \@dist, \@lens) # Inverse of lzss_encode_symbolic() and lzss_encode_fast_symbolic()

    lz77_encode($string)                         # LZ77 encoding into literals, distances, lengths and matches
    lz77_encode_symbolic(\@symbols)              # LZ77 encoding into literals, distances, lengths and matches (symbolic)

    lz77_decode(\@lits, \@dist, \@lens, \@matches)           # Inverse of lz77_encode()
    lz77_decode_symbolic(\@lits, \@dist, \@lens, \@matches)  # Inverse of lz77_encode_symbolic()

    deflate_encode(\@lits, \@dist, \@lens)   # DEFLATE-like encoding of values returned by lzss_encode()
    deflate_decode($fh)                      # Inverse of the above method

# 🔌 High-Level Function Interface

## 🧮 `create_huffman_entry`

    my $string = create_huffman_entry(\@symbols);

High-level function that generates a Huffman coding block, given an array-ref of symbols.

Example:

    my $block = create_huffman_entry([65, 65, 66, 65, 67]);
    decode_huffman_entry($block);    # [65, 65, 66, 65, 67]

## 🧮 `decode_huffman_entry`

    my $symbols = decode_huffman_entry($fh);
    my $symbols = decode_huffman_entry($string);

Inverse of `create_huffman_entry()`.

## 🧮 `create_ac_entry`

    my $string = create_ac_entry(\@symbols);

High-level function that generates an Arithmetic Coding block, given an array-ref of symbols.

## 🧮 `decode_ac_entry`

    my $symbols = decode_ac_entry($fh);
    my $symbols = decode_ac_entry($string);

Inverse of `create_ac_entry()`.

## 🧮 `create_adaptive_ac_entry`

    my $string = create_adaptive_ac_entry(\@symbols);

High-level function that generates an Adaptive Arithmetic Coding block, given an array-ref of symbols.

Unlike `create_ac_entry()`, no frequency table needs to be stored in the block: the model adapts to the data as it is decoded, which can save space on short or skewed inputs at the cost of somewhat slower encoding/decoding.

## 🧮 `decode_adaptive_ac_entry`

    my $symbols = decode_adaptive_ac_entry($fh);
    my $symbols = decode_adaptive_ac_entry($string);

Inverse of `create_adaptive_ac_entry()`.

## lz77_compress / lz77_compress_symbolic

    # With Huffman coding
    my $string = lz77_compress($data);
    my $string = lz77_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lz77_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lz77_compress($data, \&create_huffman_entry, \&lzss_encode_fast);

High-level function that performs LZ77 compression on the provided data, using the pipeline:

    1. lz77_encode
    2. create_huffman_entry(literals)
    3. create_huffman_entry(lengths)
    4. create_huffman_entry(matches)
    5. obh_encode(distances)

The function accepts either a string or an array-ref of symbols as the first argument.

## lz77_decompress / lz77_decompress_symbolic

    # With Huffman coding
    my $data = lz77_decompress($fh);
    my $data = lz77_decompress($string);

    # With Arithemtic coding
    my $data = lz77_decompress($fh, \&decode_ac_entry);
    my $data = lz77_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lz77_decompress_symbolic($fh);
    my $symbols = lz77_decompress_symbolic($string);

Inverse of `lz77_compress()` and `lz77_compress_symbolic()`, respectively.

## lzss_compress / lzss_compress_symbolic

    # With Huffman coding
    my $string = lzss_compress($data);
    my $string = lzss_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lzss_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lzss_compress($data, \&create_huffman_entry, \&lzss_encode_fast);

High-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data, using the pipeline:

    1. lzss_encode
    2. deflate_encode

The function accepts either a string or an array-ref of symbols as the first argument.

## lzss_decompress / lzss_decompress_symbolic

    # With Huffman coding
    my $data = lzss_decompress($fh);
    my $data = lzss_decompress($string);

    # With Arithmetic coding
    my $data = lzss_decompress($fh, \&decode_ac_entry);
    my $data = lzss_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lzss_decompress_symbolic($fh);
    my $symbols = lzss_decompress_symbolic($string);

Inverse of `lzss_compress()` and `lzss_compress_symbolic()`, respectively.

## lzb_compress

    my $string = lzb_compress($data);
    my $string = lzb_compress($data, \&lzss_encode_fast);   # with fast-LZ parsing

High-level function that performs byte-oriented LZSS compression, inspired by LZ4. Unlike `lz4_compress()`, this is a self-contained format specific to this module, not an interoperable LZ4 stream.

## lzb_decompress

    my $data = lzb_decompress($fh);
    my $data = lzb_decompress($string);

Inverse of `lzb_compress()`.

## lz4_compress

    my $string = lz4_compress($fh);
    my $string = lz4_compress($data);
    my $string = lz4_compress($data, \&lzss_encode_fast);   # with fast-LZ parsing

Valid LZ4 compressor, using the LZ4 Frame format, given either a string or an input file-handle.

The input data is split into chunks of length `2**17` and compressed into independent LZ4 blocks.

## lz4_decompress

    my $data = lz4_decompress($fh);
    my $data = lz4_decompress($string);

Decompress LZ4 Frame data, given either a string or an input file-handle. Concatenated LZ4 Frames are also supported.

## lzw_compress

    my $string = lzw_compress($data);

High-level function that performs LZW (Lempel-Ziv-Welch) compression on the provided data, using the pipeline:

    1. lzw_encode
    2. abc_encode

## lzw_decompress

    my $data = lzw_decompress($fh);

Performs Lempel-Ziv-Welch (LZW) decompression on the provided string or file-handle. Inverse of `lzw_compress()`.

## bwt_compress

    # Using Huffman Coding
    my $string = bwt_compress($data);

    # Using Arithmetic Coding
    my $string = bwt_compress($data, \&create_ac_entry);

High-level function that performs BWT-based compression on the provided data, using the pipeline:

    1. rle4_encode
    2. bwt_encode
    3. mtf_encode
    4. zrle_encode
    5. create_huffman_entry

## bwt_decompress

    # With Huffman coding
    my $data = bwt_decompress($fh);
    my $data = bwt_decompress($string);

    # With Arithmetic coding
    my $data = bwt_decompress($fh, \&decode_ac_entry);
    my $data = bwt_decompress($string, \&decode_ac_entry);

Inverse of `bwt_compress()`.

## bwt_compress_symbolic

    # Does Huffman coding
    my $string = bwt_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = bwt_compress_symbolic(\@symbols, \&create_ac_entry);

Similar to `bwt_compress()`, except that it accepts an arbitrary array-ref of non-negative integer values as input. It is also a bit slower on large inputs.

## bwt_decompress_symbolic

    # Using Huffman coding
    my $symbols = bwt_decompress_symbolic($fh);
    my $symbols = bwt_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = bwt_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = bwt_decompress_symbolic($string, \&decode_ac_entry);

Inverse of `bwt_compress_symbolic()`.

## bzip2_compress

    my $string = bzip2_compress($data);
    my $string = bzip2_compress($fh);

Valid Bzip2 compressor, given a string or an input file-handle. The output can be decompressed by any standard `bzip2` tool, not just by `bzip2_decompress()`.

## bzip2_decompress

    my $data = bzip2_decompress($string);
    my $data = bzip2_decompress($fh);

Valid Bzip2 decompressor, given a string or an input file-handle. Understands streams produced by the standard `bzip2` tool as well as by `bzip2_compress()`.

## gzip_compress

    my $string = gzip_compress($fh);
    my $string = gzip_compress($data);
    my $string = gzip_compress($data, \&lzss_encode_fast);  # using fast LZ-parsing

Valid GZIP compressor (RFC 1952), given a string or an input file-handle. The output is a standard `.gz` stream, decodable with `gzip -d`, `zcat`, or any GZIP-compatible library.

    use Compression::Util qw(gzip_compress);
    open my $out_fh, '>:raw', 'file.txt.gz' or die $!;
    print $out_fh gzip_compress("Hello, world!\n");

## gzip_decompress

    my $data = gzip_decompress($string);
    my $data = gzip_decompress($fh);

Valid GZIP decompressor (RFC 1952), given a string or an input file-handle. Understands streams produced by the standard `gzip` tool as well as by `gzip_compress()`, including multiple concatenated members.

## zlib_compress

    my $string = zlib_compress($fh);
    my $string = zlib_compress($data);
    my $string = zlib_compress($data, \&lzss_encode_fast);  # using fast LZ-parsing

Valid ZLIB compressor (RFC 1950), given a string or an input file-handle.

## zlib_decompress

    my $data = zlib_decompress($string);
    my $data = zlib_decompress($fh);

Valid ZLIB decompressor (RFC 1950), given a string or an input file-handle.

## mrl_compress / mrl_compress_symbolic

    # Does Huffman coding
    my $enc = mrl_compress($str);
    my $enc = mrl_compress(\@symbols);

    # Does Arithmetic coding
    my $enc = mrl_compress($str, \&create_ac_entry);
    my $enc = mrl_compress(\@symbols, \&create_ac_entry);

A fast compression method (no BWT stage, so it is cheaper but generally less effective than `bwt_compress()`), using the following pipeline:

    1. mtf_encode
    2. zrle_encode
    3. rle4_encode
    4. create_huffman_entry

It accepts either a string or an arbitrary array-ref of non-negative integer values as input; `mrl_compress()` and `mrl_compress_symbolic()` are, in fact, the same function under two names.

## mrl_decompress / mrl_decompress_symbolic

    # With Huffman coding
    my $data = mrl_decompress($fh);
    my $data = mrl_decompress($string);

    # Symbolic, with Huffman coding
    my $symbols = mrl_decompress_symbolic($fh);
    my $symbols = mrl_decompress_symbolic($string);

    # Symbolic, with Arithmetic coding
    my $symbols = mrl_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = mrl_decompress_symbolic($string, \&decode_ac_entry);

Inverse of `mrl_compress()` and `mrl_compress_symbolic()`.

# 🔌 Medium-Level Function Interface

## frequencies

    my $freq = frequencies(\@symbols);

Returns a hash-ref dictionary with frequencies, given an array-ref of symbols. For example:

    frequencies([65, 65, 66, 65, 67]);   # { 65 => 3, 66 => 1, 67 => 1 }

## deltas

    my $deltas = deltas(\@integers);

Computes the differences between consecutive integers, returning an array-ref, where the first delta is relative to `0`. For example:

    deltas([10, 12, 13, 11]);   # [10, 2, 1, -2]

## accumulate

    my $integers = accumulate(\@deltas);

Inverse of `deltas()`. For example:

    accumulate([10, 2, 1, -2]);   # [10, 12, 13, 11]

## delta_encode

    my $string = delta_encode(\@integers);

Encodes a sequence of integers (including negative integers) using Delta + Run-length + Elias omega coding, returning a binary string.

Delta encoding calculates the difference between consecutive integers in the sequence and encodes these differences using Elias omega coding. When it's beneficial, runs of identical symbols are collapsed with RLE.

This method supports both positive and negative integers, and is well suited to sequences that increase monotonically or vary smoothly, such as timestamps or sorted indices.

## delta_decode

    # Given a file-handle
    my $integers = delta_decode($fh);

    # Given a string
    my $integers = delta_decode($string);

Inverse of `delta_encode()`.

## fibonacci_encode

    my $string = fibonacci_encode(\@symbols);

Encodes a sequence of non-negative integers using Fibonacci coding, returning a binary string. Fibonacci codes are self-synchronizing (a corrupted bit cannot propagate errors past the next codeword) and tend to compress small values well.

## fibonacci_decode

    # Given a file-handle
    my $symbols = fibonacci_decode($fh);

    # Given a binary string
    my $symbols = fibonacci_decode($string);

Inverse of `fibonacci_encode()`.

## elias_gamma_encode

    my $string = elias_gamma_encode(\@symbols);

Encodes a sequence of non-negative integers using Elias Gamma coding, returning a binary string. Elias Gamma coding is simple and fast, and works best when small values dominate the sequence.

## elias_gamma_decode

    # Given a file-handle
    my $symbols = elias_gamma_decode($fh);

    # Given a binary string
    my $symbols = elias_gamma_decode($string);

Inverse of `elias_gamma_encode()`.

## elias_omega_encode

    my $string = elias_omega_encode(\@symbols);

Encodes a sequence of non-negative integers using Elias Omega coding, returning a binary string. Compared to Elias Gamma, Omega coding scales better to large values, at a small cost for small ones.

## elias_omega_decode

    # Given a file-handle
    my $symbols = elias_omega_decode($fh);

    # Given a binary string
    my $symbols = elias_omega_decode($string);

Inverse of `elias_omega_encode()`.

## abc_encode

    my $string = abc_encode(\@symbols);

Encodes a sequence of non-negative integers using the Adaptive Binary Concatenation encoding method.

This method is particularly effective in encoding a sequence of integers that are in ascending order or have roughly the same size in binary (this is why it is used as the default entropy coder for LZW codes in `lzw_compress()`, since LZW dictionary indices grow roughly monotonically).

## abc_decode

    # Given a file-handle
    my $symbols = abc_decode($fh);

    # Given a binary string
    my $symbols = abc_decode($string);

Inverse of `abc_encode()`.

## obh_encode

    # With Huffman Coding
    my $string = obh_encode(\@symbols);

    # With Arithmetic Coding
    my $string = obh_encode(\@symbols, \&create_ac_entry);

Encodes a sequence of non-negative integers using offset bits and Huffman coding.

This method is particularly effective in encoding a sequence of moderately large random integers, such as the list of distances returned by `lzss_encode()` (which is exactly how `lz77_compress()` uses it internally).

## obh_decode

    # Given a file-handle
    my $symbols = obh_decode($fh);                        # Huffman decoding
    my $symbols = obh_decode($fh, \&decode_ac_entry);     # Arithmetic decoding

    # Given a binary string
    my $symbols = obh_decode($string);                    # Huffman decoding
    my $symbols = obh_decode($string, \&decode_ac_entry); # Arithmetic decoding

Inverse of `obh_encode()`.

## bwt_encode

    my ($bwt, $idx) = bwt_encode($string);
    my ($bwt, $idx) = bwt_encode($string, $lookahead_len);

Applies the Burrows-Wheeler Transform (BWT) to a given string, returning the transformed string and the index of the original string among the sorted rotations.

By default, `$lookahead_len` is `128` (see `bwt_sort()`).

Example:

    my ($bwt, $idx) = bwt_encode("banana");
    bwt_decode($bwt, $idx);   # "banana"

## bwt_decode

    my $string = bwt_decode($bwt, $idx);

Reverses the Burrows-Wheeler Transform (BWT) applied to a string.

The function returns the original string.

## bwt_encode_symbolic

    my ($bwt_symbols, $idx) = bwt_encode_symbolic(\@symbols);

Applies the Burrows-Wheeler Transform (BWT) to a sequence of symbolic elements.

## bwt_decode_symbolic

    my $symbols = bwt_decode_symbolic(\@bwt_symbols, $idx);

Reverses the Burrows-Wheeler Transform (BWT) applied to a sequence of symbolic elements.

## mtf_encode

    my $mtf = mtf_encode(\@symbols, \@alphabet);
    my ($mtf, $alphabet) = mtf_encode(\@symbols);

Performs Move-To-Front (MTF) encoding on a sequence of symbols (also accepts a plain string in place of `\@symbols`).

The function returns the encoded MTF sequence and the sorted list of unique symbols in the input data, representing the alphabet.

Optionally, the alphabet can be provided as a second argument. When two arguments are provided, only the MTF sequence is returned.

Example:

    my ($mtf, $alphabet) = mtf_encode([2, 2, 5, 2, 9]);
    # $mtf      = [0, 0, 1, 1, 2]
    # $alphabet = [2, 5, 9]
    mtf_decode($mtf, $alphabet);    # [2, 2, 5, 2, 9]

## mtf_decode

    my $symbols = mtf_decode(\@mtf, \@alphabet);

Inverse of `mtf_encode()`.

## encode_alphabet / encode_alphabet_256

    my $string = encode_alphabet(\@alphabet);        # supports arbitrarily large symbols
    my $string = encode_alphabet_256(\@alphabet);    # limited to symbols [0..255]

Encode a sorted alphabet of symbols into a binary string. Use `encode_alphabet_256()` when you know every symbol fits in a byte (for instance, the alphabet produced by `mtf_encode()` on ordinary text); it produces a more compact header than the general-purpose `encode_alphabet()`.

## decode_alphabet / decode_alphabet_256

    my $alphabet = decode_alphabet($fh);
    my $alphabet = decode_alphabet($string);

    my $alphabet = decode_alphabet_256($fh);
    my $alphabet = decode_alphabet_256($string);

Decodes an encoded alphabet, given a file-handle or a binary string, returning an array-ref of symbols. Inverse of `encode_alphabet()` and `encode_alphabet_256()`, respectively.

## run_length

    my $rl = run_length(\@symbols);
    my $rl = run_length(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements.

It takes two parameters: `\@symbols`, representing an array of symbols, and `$max_run`, indicating the maximum run length allowed.

The function returns a 2D-array, with pairs: `[symbol, run_length]`, such that the following code reconstructs the `\@symbols` array:

    my @symbols = map { ($_->[0]) x $_->[1] } @$rl;

By default, the maximum run-length is unlimited. Example:

    run_length([1, 1, 1, 2, 2, 3]);   # [[1, 3], [2, 2], [3, 1]]

## rle4_encode

    my $rle4 = rle4_encode($string);
    my $rle4 = rle4_encode(\@symbols);
    my $rle4 = rle4_encode(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements, specifically designed for runs of four or more consecutive symbols (shorter runs are left untouched, which is cheaper when most of the data doesn't repeat).

It takes two parameters: `\@symbols`, representing an array of symbols, and `$max_run`, indicating the maximum run length allowed during encoding.

The function returns the encoded RLE sequence as an array-ref of symbols.

By default, the maximum run-length is limited to `255`.

## rle4_decode

    my $symbols = rle4_decode(\@rle4);
    my $symbols = rle4_decode($rle4_string);

Inverse of `rle4_encode()`.

## zrle_encode

    my $zrle = zrle_encode(\@symbols);

Performs Zero-Run-Length Encoding (ZRLE) on a sequence of symbolic elements, returning the encoded ZRLE sequence as an array-ref of symbols.

This function efficiently encodes runs of zeros, but also increments each symbol by `1` (so that `0` is freed up to serve purely as a run marker in the output alphabet -- useful right after `mtf_encode()`, whose output is dominated by zeros).

## zrle_decode

    my $symbols = zrle_decode($zrle);

Inverse of `zrle_encode()`.

## ac_encode

    my ($bitstring, $freq) = ac_encode(\@symbols);

Performs (static) Arithmetic Coding on the provided symbols.

It takes a single parameter, `\@symbols`, representing the symbols to be encoded.

The function returns two values: `$bitstring`, which is a string of 1s and 0s, and `$freq`, representing the frequency table used for encoding -- this table must be kept (or otherwise reconstructed) in order to decode the data with `ac_decode()`, since it is not embedded in `$bitstring`. (`create_ac_entry()` takes care of storing it for you.)

## ac_decode

    my $symbols = ac_decode($bits_fh, \%freq);
    my $symbols = ac_decode($bitstring, \%freq);

Performs Arithmetic Coding decoding using the provided frequency table and a string of 1s and 0s. Inverse of `ac_encode()`.

It takes two parameters: `$bitstring`, representing a string of 1s and 0s containing the arithmetic coded data, and `\%freq`, representing the frequency table used for encoding.

The function returns the decoded sequence of symbols.

## adaptive_ac_encode

    my ($bitstring, $alphabet) = adaptive_ac_encode(\@symbols);

Performs Adaptive Arithmetic Coding on the provided symbols.

It takes a single parameter, `\@symbols`, representing the symbols to be encoded.

The function returns two values: `$bitstring`, which is a string of 1s and 0s, and `$alphabet`, which is an array-ref of distinct sorted symbols. Unlike `ac_encode()`, no per-symbol frequencies need to be stored -- only the alphabet -- because the model adapts as it goes.

## adaptive_ac_decode

    my $symbols = adaptive_ac_decode($bits_fh, \@alphabet);
    my $symbols = adaptive_ac_decode($bitstring, \@alphabet);

Performs Adaptive Arithmetic Coding decoding using the provided alphabet and a string of 1s and 0s.

It takes two parameters: `$bitstring`, representing a string of 1s and 0s containing the adaptive arithmetic coded data, and `\@alphabet`, representing the array of distinct sorted symbols that appear in the encoded data.

The function returns the decoded sequence of symbols.

## lzw_encode

    my $symbols = lzw_encode($string);

Performs Lempel-Ziv-Welch (LZW) encoding on the provided string.

It takes a single parameter, `$string`, representing the data to be encoded.

The function returns an array-ref of symbols (dictionary indices).

## lzw_decode

    my $string = lzw_decode(\@symbols);

Performs Lempel-Ziv-Welch (LZW) decoding on the provided symbols. Inverse of `lzw_encode()`.

The function returns the decoded string.

# 🔌 Low-Level Function Interface

## crc32

    my $int32 = crc32($data);
    my $int32 = crc32($data, $prev_crc32);

Compute the CRC32 checksum of a given string, as used by GZIP and ZLIB. The optional second argument allows a checksum to be computed incrementally, over successive chunks:

    my $crc = 0;
    $crc = crc32($chunk1, $crc);
    $crc = crc32($chunk2, $crc);

## adler32

    my $int32 = adler32($data);
    my $int32 = adler32($data, $prev_adler32);

Compute the Adler-32 checksum of a given string, as used by ZLIB. Like `crc32()`, it can be computed incrementally by passing the running checksum as the second argument; note that its identity value is `1`, not `0`.

## read_bit

    my $bit = read_bit($fh, \$buffer);

Reads a single bit from a file-handle `$fh` (MSB order).

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle. Pass the same `\$buffer` scalar-ref on every call so left-over bits from a partially consumed byte carry over correctly to the next read.

## read_bit_lsb

    my $bit = read_bit_lsb($fh, \$buffer);

Reads a single bit from a file-handle `$fh` (LSB order).

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## read_bits

    my $bitstring = read_bits($fh, $bits_len);

Reads a specified number of bits (`$bits_len`) from a file-handle (`$fh`) and returns them as a string, in MSB order.

## read_bits_lsb

    my $bitstring = read_bits_lsb($fh, $bits_len);

Reads a specified number of bits (`$bits_len`) from a file-handle (`$fh`) and returns them as a string, in LSB order.

## int2bits

    my $bitstring = int2bits($symbol, $size)

Convert a non-negative integer to a bitstring of width `$size`, in MSB order.

Example:

    int2bits(5, 8);        # "00000101"
    bits2int_from_string(int2bits(5, 8));   # see note below

Note: to turn a bitstring back into a packed binary string (rather than reading it from a file-handle with `bits2int()`), use `pack('B*', $bitstring)`.

## int2bits_lsb

    my $bitstring = int2bits_lsb($symbol, $size)

Convert a non-negative integer to a bitstring of width `$size`, in LSB order.

## int2bytes

    my $string = int2bytes($symbol, $size);

Convert a non-negative integer to a byte-string of width `$size`, in MSB order. For example, `int2bytes(1, 4)` returns the 4-byte big-endian encoding of `1`.

## int2bytes_lsb

    my $string = int2bytes_lsb($symbol, $size);

Convert a non-negative integer to a byte-string of width `$size`, in LSB order (little-endian).

## bits2int

    my $integer = bits2int($fh, $size, \$buffer);

Read `$size` bits from a file-handle `$fh` and convert them to an integer, in MSB order. Inverse of `int2bits()`.

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## bits2int_lsb

    my $integer = bits2int_lsb($fh, $size, \$buffer);

Read `$size` bits from a file-handle `$fh` and convert them to an integer, in LSB order. Inverse of `int2bits_lsb()`.

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## bytes2int

    my $integer = bytes2int($fh, $n);
    my $integer = bytes2int($str, $n);

Read `$n` bytes from a file-handle `$fh` or from a string `$str` and convert them to an integer, in MSB order.

## bytes2int_lsb

    my $integer = bytes2int_lsb($fh, $n);
    my $integer = bytes2int_lsb($str, $n);

Read `$n` bytes from a file-handle `$fh` or from a string `$str` and convert them to an integer, in LSB order.

## string2symbols

    my $symbols = string2symbols($string)

Returns an array-ref of code points, given a string. Equivalent to `[unpack('C*', $string)]`.

## symbols2string

    my $string = symbols2string(\@symbols)

Returns a string, given an array-ref of code points. Equivalent to `pack('C*', @$symbols)`. Inverse of `string2symbols()`.

## read_null_terminated

    my $string = read_null_terminated($fh)

Read a string from file-handle `$fh` that ends with a NULL character ("\0"). The terminator itself is consumed but not included in the returned string.

## binary_vrl_encode

    my $bitstring_enc = binary_vrl_encode($bitstring);

Given a string of 1s and 0s, returns back a bitstring of 1s and 0s encoded using variable run-length encoding.

## binary_vrl_decode

    my $bitstring = binary_vrl_decode($bitstring_enc);

Given an encoded bitstring, returned by `binary_vrl_encode()`, gives back the decoded string of 1s and 0s.

## bwt_sort

    my $indices = bwt_sort($string);
    my $indices = bwt_sort($string, $lookahead_len);

Low-level function that sorts the rotations of a given string using the Burrows-Wheeler Transform (BWT) algorithm.

It takes two parameters: `$string`, which is the input string to be transformed, and `$lookahead_len` (optional), representing the length of look-ahead during sorting, which trades memory for speed (O(n \* `$lookahead_len`) space). By default, `$lookahead_len` is `128`.

The function returns an array-ref of indices.

There is probably no need to call this function explicitly. Use `bwt_encode()` instead!

## bwt_sort_symbolic

    my $indices = bwt_sort_symbolic(\@symbols);

Low-level function that sorts the rotations of a sequence of symbolic elements using the Burrows-Wheeler Transform (BWT) algorithm. Unlike `bwt_sort()`, this uses O(n) space with no look-ahead parameter, and is somewhat slower for large inputs.

It takes a single parameter `\@symbols`, which represents the input sequence of symbolic elements. The function returns an array-ref of indices.

There is probably no need to call this function explicitly. Use `bwt_encode_symbolic()` instead!

## huffman_from_freq

    my $dict = huffman_from_freq(\%freq);
    my ($dict, $rev_dict) = huffman_from_freq(\%freq);

Low-level function that constructs Huffman prefix codes, based on the frequency of symbols provided in a hash table.

It takes a single parameter, `\%freq`, representing the hash table where keys are symbols, and values are their corresponding frequencies (such as the hash-ref returned by `frequencies()`).

The function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

## huffman_from_symbols

    my $dict = huffman_from_symbols(\@symbols);
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);

Low-level function that constructs Huffman prefix codes, given an array-ref of symbols. Equivalent to `huffman_from_freq(frequencies(\@symbols))`.

It takes a single parameter, `\@symbols`, from which it computes the frequency of each symbol and generates the corresponding Huffman prefix codes.

The function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

## huffman_from_code_lengths

    my $dict = huffman_from_code_lengths(\@code_lengths);
    my ($dict, $rev_dict) = huffman_from_code_lengths(\@code_lengths);

    my $dict = huffman_from_code_lengths(\%code_lengths);
    my ($dict, $rev_dict) = huffman_from_code_lengths(\%code_lengths);

Low-level function that constructs a dictionary of canonical prefix codes as defined in RFC 1951 (Section 3.2.2), given an array-ref of code lengths or a hash-ref of `symbol => length` values.

It takes a single parameter, `\@code_lengths`, where entry `$i` in the array corresponds to the code length for symbol `$i` (a length of `0` means the symbol is unused).

Similarly, when a hash-ref table is given, `\%code_lengths`, keys are the symbols and values are the code lengths. This variant is useful for large symbols, where an array indexed by symbol value would be wastefully sparse.

In list context, the function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

In scalar context, it returns only the `$dict` table.

This is the function used to reconstruct Huffman codes purely from the list of code lengths transmitted in a DEFLATE header, without needing to re-run the frequency-based algorithm.

## huffman_encode

    my $bitstring = huffman_encode(\@symbols, $dict);

Low-level function that performs Huffman encoding on a sequence of symbols using a provided dictionary, returned by `huffman_from_freq()`, `huffman_from_symbols()`, or `huffman_from_code_lengths()`.

It takes two parameters: `\@symbols`, representing the sequence of symbols to be encoded, and `$dict`, representing the Huffman dictionary mapping symbols to their corresponding Huffman codes.

The function returns a concatenated string of 1s and 0s, representing the Huffman-encoded sequence of symbols.

## huffman_decode

    my $symbols = huffman_decode($bitstring, $rev_dict);

Low-level function that decodes a Huffman-encoded binary string into a sequence of symbols using a provided reverse dictionary.

It takes two parameters: `$bitstring`, representing the Huffman-encoded string of 1s and 0s, as returned by `huffman_encode()`, and `$rev_dict`, representing the reverse dictionary mapping Huffman codes to their corresponding symbols.

The function returns the decoded sequence of symbols as an array-ref.

Putting the last few functions together, without using `create_huffman_entry()`'s bookkeeping:

    my @symbols = (65, 65, 66, 65, 67, 65, 66);
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);

    my $bitstring = huffman_encode(\@symbols, $dict);
    my $decoded   = huffman_decode($bitstring, $rev_dict);

    "@$decoded" eq "@symbols" or die "mismatch";

## lz77_encode / lz77_encode_symbolic

    my ($literals, $distances, $lengths, $matches) = lz77_encode($string);
    my ($literals, $distances, $lengths, $matches) = lz77_encode(\@symbols);

Low-level function that combines LZSS with ideas from the LZ4 method (interleaving literal runs and matches into parallel arrays, rather than a single flat token stream).

The function returns four values:

    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of literal-run lengths
    $matches    # array-ref of match lengths

The output can be decoded with `lz77_decode()` and `lz77_decode_symbolic()`, respectively. `lz77_encode_symbolic()` is currently the same underlying function as `lz77_encode()`, since `lz77_encode()` already dispatches on whether it was given a string or an array-ref.

Ignores `$LZ_MAX_LEN`, always using unlimited match lengths (see ["\$LZ_MAX_LEN"](lz_max_len)).

## lz77_decode / lz77_decode_symbolic

    my $string  = lz77_decode(\@literals, \@distances, \@lengths, \@matches);
    my $symbols = lz77_decode_symbolic(\@literals, \@distances, \@lengths, \@matches);

Low-level function that performs decoding using the provided literals, distances, lengths and matches, returned by LZ77 encoding.

Inverse of `lz77_encode()` and `lz77_encode_symbolic()`, respectively.

## lzss_encode / lzss_encode_fast / lzss_encode_symbolic / lzss_encode_fast_symbolic

    # Standard version -- best compression
    my ($literals, $distances, $lengths) = lzss_encode($data, %params);
    my ($literals, $distances, $lengths) = lzss_encode(\@symbols, %params);

    # Faster version -- lower chain length, still string-hash based
    my ($literals, $distances, $lengths) = lzss_encode_fast($data, %params);
    my ($literals, $distances, $lengths) = lzss_encode_fast(\@symbols, %params);

Low-level function that applies the LZSS (Lempel-Ziv-Storer-Szymanski) algorithm on the provided data. See ["CHOOSING AN LZSS ENCODER"](choosing-an-lzss-encoder) for how this compares to `lzss_encode_fast()`.

The accepted `%params` are:

    min_len         => $LZ_MIN_LEN,
    max_len         => $LZ_MAX_LEN,
    max_dist        => $LZ_MAX_DIST,
    max_chain_len   => $LZ_MAX_CHAIN_LEN,

Any key omitted from `%params` falls back to the corresponding package variable (see ["PACKAGE VARIABLES"](package-variables)).

The function returns three values:

    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of match lengths

The output can be decoded with `lzss_decode()` and `lzss_decode_symbolic()`, respectively.

## lzss_decode / lzss_decode_symbolic

    my $string  = lzss_decode(\@literals, \@distances, \@lengths);
    my $symbols = lzss_decode_symbolic(\@literals, \@distances, \@lengths);

Low-level function that decodes the LZSS encoding, using the provided literals, distances, and lengths of matched sub-strings.

Inverse of `lzss_encode()` and `lzss_encode_fast()` (both produce output in the same `($literals, $distances, $lengths)` shape).

## deflate_encode

    # Returns a binary string
    my $string = deflate_encode(\@literals, \@distances, \@lengths);
    my $string = deflate_encode(\@literals, \@distances, \@lengths, \&create_ac_entry);

Low-level function that encodes the results returned by `lzss_encode()` or `lzss_encode_fast()`, using a DEFLATE-like approach, combined with Huffman coding by default (or the given `$entropy_sub`).

## deflate_decode

    # Huffman decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh);
    my ($literals, $distances, $lengths) = deflate_decode($string);

    # Arithmetic decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh, \&decode_ac_entry);
    my ($literals, $distances, $lengths) = deflate_decode($string, \&decode_ac_entry);

Inverse of `deflate_encode()`.

## make_deflate_tables

    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($max_dist, $max_len);

Low-level function that returns a list of tables used in encoding the relative back-reference distances and lengths returned by `lzss_encode()` and `lzss_encode_fast()`.

When no arguments are provided:

    $max_dist = $Compression::Util::LZ_MAX_DIST
    $max_len  = $Compression::Util::LZ_MAX_LEN

There is no need to call this function explicitly. Use `deflate_encode()` instead!

## find_deflate_index

    my $index = find_deflate_index($value, $DISTANCE_SYMBOLS);

Low-level function that returns the index inside the DEFLATE tables (as returned by `make_deflate_tables()`) for a given value.

## deflate_create_block_type_0_header

    my $bt0_header = deflate_create_block_type_0_header($chunk);

Creates the header for a DEFLATE block of type 0 (uncompressed), as a bitstring, without including the block code number `00`.

The length of the `$chunk` must not exceed `2^16 - 1`.

To create a DEFLATE block of type 0, including the content, use:

    my $block_type_0 = pack('b*', '00') . pack('b*', $bt0_header) . $chunk;

which can be recovered as:

    open my $fh, '<:raw', \$block_type_0;
    my ($buffer, $search_window) = ('', '');
    my $chunk = deflate_extract_next_block($fh, \$buffer, \$search_window);

## deflate_create_block_type_1

    my $bitstring = deflate_create_block_type_1($literals, $distances, $lengths);

Creates a DEFLATE block of type 1 (fixed prefix-codes), as a bitstring, given the array-refs of literals, distances and lengths, returned by `lzss_encode()`.

This type of block uses fixed prefix-codes and is pretty fast, at the cost of a somewhat lower compression ratio than type 2.

## deflate_create_block_type_2

    my $bitstring = deflate_create_block_type_2($literals, $distances, $lengths);

Creates a DEFLATE block of type 2 (dynamic prefix-codes), as a bitstring, given the array-refs of literals, distances and lengths, returned by `lzss_encode()`.

This type of block uses dynamic prefix-codes (Huffman codes) and produces good compression ratio on most inputs.

## deflate_extract_block_type_0

    my $data = deflate_extract_block_type_0($fh, \$buffer, \$search_window);

Given an input filehandle, it extracts a DEFLATE block of type 0 (uncompressed).

    my ($buffer, $search_window) = ('', '');
    my $block_type = bits2int_lsb($fh, 2, \$buffer);
    $block_type == 0 or die "Not a block of type 0";
    my $decoded_chunk = deflate_extract_block_type_0($fh, \$buffer, \$search_window);

## deflate_extract_block_type_1

    my $data = deflate_extract_block_type_1($fh, \$buffer, \$search_window);

Given an input filehandle, a bitstring buffer and a search window, it extracts a DEFLATE block of type 1 (fixed prefix-codes).

    my ($buffer, $search_window) = ('', '');
    my $block_type = bits2int_lsb($fh, 2, \$buffer);
    $block_type == 1 or die "Not a block of type 1";
    my $decoded_chunk = deflate_extract_block_type_1($fh, \$buffer, \$search_window);

## deflate_extract_block_type_2

    my $data = deflate_extract_block_type_2($fh, \$buffer, \$search_window);

Given an input filehandle, a bitstring buffer and a search window, it extracts a DEFLATE block of type 2 (dynamic prefix-codes).

    my ($buffer, $search_window) = ('', '');
    my $block_type = bits2int_lsb($fh, 2, \$buffer);
    $block_type == 2 or die "Not a block of type 2";
    my $decoded_chunk = deflate_extract_block_type_2($fh, \$buffer, \$search_window);

## deflate_extract_next_block

    my $data = deflate_extract_next_block($fh, \$buffer, \$search_window);

Given an input filehandle, a bitstring buffer and a search window, it extracts the next DEFLATE block, dispatching automatically to `deflate_extract_block_type_0()`, `deflate_extract_block_type_1()`, or `deflate_extract_block_type_2()` based on the block-type bits. The next two bits in the input file-handle (or in the bitstring buffer) must contain the block-type number.

This is the function `gzip_decompress()` and `zlib_decompress()` use internally to walk a stream one block at a time; `$search_window` accumulates the last 32 KiB of decoded output across calls, as required for resolving back-references near a block boundary.

# 📤 Exporting Functions

Each function can be exported individually, as:

    use Compression::Util qw(bwt_compress);

By specifying the **:all** keyword, will export all the exportable functions:

    use Compression::Util qw(:all);

The package variables (`$VERBOSE`, `$LZ_MIN_LEN`, `$LZ_MAX_LEN`, `$LZ_MAX_DIST`, `$LZ_MAX_CHAIN_LEN`, `$LZ_MAX_CHAIN_WIDTH`) are **not** included in `:all`; import them explicitly by name if needed (see ["PACKAGE VARIABLES"](package-variables)).

Nothing is exported by default.

<a id="examples"></a>

# 💡 Examples

The functions can be combined in various ways, easily creating novel compression methods, as illustrated in the following examples.

## Combining LZSS + MRL compression:

    my $enc = lzss_compress($str, \&mrl_compress_symbolic);
    my $dec = lzss_decompress($enc, \&mrl_decompress_symbolic);

## Combining LZ77 + OBH encoding:

    my $enc = lz77_compress($str, \&obh_encode);
    my $dec = lz77_decompress($enc, \&obh_decode);

## Combining LZSS + symbolic BWT compression:

    my $enc = lzss_compress($str, \&bwt_compress_symbolic);
    my $dec = lzss_decompress($enc, \&bwt_decompress_symbolic);

## Combining BWT + symbolic LZSS:

    my $enc = bwt_compress($str, \&lzss_compress_symbolic);
    my $dec = bwt_decompress($enc, \&lzss_decompress_symbolic);

## Combining LZW + Fibonacci encoding:

    my $enc = lzw_compress($str, \&fibonacci_encode);
    my $dec = lzw_decompress($enc, \&fibonacci_decode);

## Combining BWT + symbolic LZ77 + symbolic MRL:

    my $enc = bwt_compress($str, sub ($s) { lz77_compress_symbolic($s, \&mrl_compress_symbolic) });
    my $dec = bwt_decompress($enc, sub ($s) { lz77_decompress_symbolic($s, \&mrl_decompress_symbolic) });

## Combining LZ77 + BWT compression + Fibonacci encoding + Huffman coding + OBH encoding + MRL compression:

    # Compression
    my $enc = do {
        my ($literals, $distances, $lengths, $matches) = lz77_encode($str);
        bwt_compress(symbols2string($literals))
          . fibonacci_encode($lengths)
          . create_huffman_entry($matches)
          . obh_encode($distances, \&mrl_compress_symbolic);
    };

    # Decompression
    my $dec = do {
        open my $fh, '<:raw', \$enc;
        my $literals  = string2symbols(bwt_decompress($fh));
        my $lengths   = fibonacci_decode($fh);
        my $matches   = decode_huffman_entry($fh);
        my $distances = obh_decode($fh, \&mrl_decompress_symbolic);
        lz77_decode($literals, $distances, $lengths, $matches);
    };

## Compressing a list of integers directly (no string involved):

Delta coding is a good fit whenever the data is naturally a sequence of integers rather than text -- for example, a column of sorted database IDs, or timestamps:

    my @ids = (1000, 1001, 1002, 1050, 1051, 1052, 2000);

    my $enc = delta_encode(\@ids);
    my $dec = delta_decode($enc);

    "@$dec" eq "@ids" or die "mismatch";

## Choosing an entropy coder based on input size:

Adaptive Arithmetic Coding avoids storing an explicit frequency table, which tends to pay off on short inputs, while plain Huffman coding (via `create_huffman_entry()`) is typically faster and does just as well once the input is large enough to amortize the table's size:

    sub smart_compress ($data) {
        length($data) < 1024
          ? ("A", create_adaptive_ac_entry(string2symbols($data)))
          : ("H", create_huffman_entry(string2symbols($data)));
    }

    sub smart_decompress ($tag, $fh) {
        my $symbols =
            $tag eq 'A' ? decode_adaptive_ac_entry($fh)
          : $tag eq 'H' ? decode_huffman_entry($fh)
          :                die "unknown tag: $tag";
        symbols2string($symbols);
    }

## Tuning LZ parsing for speed vs. ratio:

    use Compression::Util qw(:all);

    # Favor speed: shallower search, fewer chain positions remembered
    {
        local $Compression::Util::LZ_MAX_CHAIN_LEN = 4;
        my $fast_enc = lzss_compress($data);
    }

    # Favor ratio: deeper search (default is 32)
    {
        local $Compression::Util::LZ_MAX_CHAIN_LEN = 128;
        my $tight_enc = lzss_compress($data);
    }

<a id="references"></a>

# 📖 References

- DEFLATE Compressed Data Format Specification <https://datatracker.ietf.org/doc/html/rfc1951>

- GZIP file format specification <https://datatracker.ietf.org/doc/html/rfc1952>

- ZLIB Compressed Data Format Specification <https://datatracker.ietf.org/doc/html/rfc1950>

- BZIP2 Format Specification, by Joe Tsai: <https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf>

- LZ4 Frame format <https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md>

- LZ4 Block format <https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md>

- Data Compression (Summer 2023) - Lecture 4 - The Unix 'compress' Program: <https://youtube.com/watch?v=1cJL9Va80Pk>

- Data Compression (Summer 2023) - Lecture 5 - Basic Techniques: <https://youtube.com/watch?v=TdFWb8mL5Gk>

- Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip): <https://youtube.com/watch?v=SJPvNi4HrWQ>

- Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT): <https://youtube.com/watch?v=rQ7wwh4HRZM>

- Data Compression (Summer 2023) - Lecture 13 - BZip2: <https://youtube.com/watch?v=cvoZbBZ3M2A>

- Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits: <https://youtube.com/watch?v=EqKbT3QdtOI>

- Information Retrieval WS 17/18, Lecture 4: Compression, Codes, Entropy: <https://youtube.com/watch?v=A_F94FV21Ek>

- COMP526 7-5 SS7.4 Run length encoding: <https://youtube.com/watch?v=3jKLjmV1bL8>

- COMP526 Unit 7-6 2020-03-24 Compression - Move-to-front transform: <https://youtube.com/watch?v=Q2pinaj3i9Y>

- Basic arithmetic coder in C++: <https://github.com/billbird/arith32>

# 🔗 Repository

- GitHub: <https://github.com/trizen/Compression-Util>

# 🐛 Bugs & Limitations

Please report any bugs or feature requests to: <https://github.com/trizen/Compression-Util>.

<a id="see-also"></a>

# 🔎 See Also

- Compress::Zlib, IO::Compress::Gzip, IO::Compress::Bzip2 -- bindings to the corresponding C libraries, generally much faster than this pure-Perl implementation for production use.

- Compress::Raw::Zlib -- low-level bindings, if only speed matters and not portability.

Use **Compression::Util** when you want a pure-Perl implementation with no XS/C dependencies, when you want to inspect or hand-tune every stage of the pipeline, or for learning how these algorithms work.

# 👤 Author

Daniel "Trizen" Șuteu

# 🙏 Acknowledgements

Special thanks to professor Bill Bird for the awesome YouTube lectures on data compression.

# 📄 License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.38.2 or, at your option, any later version of Perl 5 you may have available.
