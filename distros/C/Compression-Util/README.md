# NAME

Compression::Util - Implementation of various techniques used in data compression.

# SYNOPSIS

```perl
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
```

# DESCRIPTION

**Compression::Util** is a function-based module, implementing various techniques used in data compression, such as:

    * Burrows-Wheeler transform
    * Move-to-front transform
    * Huffman Coding
    * Arithmetic Coding (in fixed bits)
    * Run-length encoding
    * Fibonacci coding
    * Elias gamma/omega coding
    * Delta coding
    * Bzip2-like compression
    * LZ77/LZSS compression
    * LZW compression

The provided techniques can be easily combined in various ways to create powerful compressors, such as the Bzip2 compressor, which is a pipeline of the following methods:

    1. Run-length encoding (RLE4)
    2. Burrows-Wheeler transform (BWT)
    3. Move-to-front transform (MTF)
    4. Zero run-length encoding (ZRLE)
    5. Huffman coding

This functionality is provided by the function `bwt_compress()`, which can be explicitly implemented as:

```perl
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
```

## TERMINOLOGY

### bit

A bit value is either `1` or `0`.

### bitstring

A bitstring is a string containing only 1s and 0s.

### byte

A byte value is an integer between `0` and `255`, inclusive.

### string

A string means a binary (non-UTF\*) string.

### symbols

An array of symbols means an array of non-negative integer values.

### filehandle

A filehandle is denoted by `$fh`.

The encoding of file-handles must be set to `:raw`.

# PACKAGE VARIABLES

**Compression::Util** provides the following package variables:

```perl
    $Compression::Util::VERBOSE = 0;           # true to enable verbose/debug mode

    $Compression::Util::LZ_MIN_LEN = 4;        # minimum match length in LZ parsing
    $Compression::Util::LZ_MAX_LEN = 258;      # maximum match length in LZ parsing

    $Compression::Util::LZ_MAX_DIST = ~0;      # maximum back-reference distance allowed
    $Compression::Util::LZ_MAX_CHAIN_LEN = 32; # how many recent positions to remember for each match in LZ parsing
```

These package variables can also be imported as:

```perl
    use Compression::Util qw(
        $LZ_MIN_LEN
        $LZ_MAX_LEN
        $LZ_MAX_DIST
        $LZ_MAX_CHAIN_LEN
    );
```

## $LZ\_MIN\_LEN

Minimum length of a match in LZ parsing. The value must be an integer greater than or equal to `2`. Larger values will result in faster parsing, but lower compression ratio.

By default, `$LZ_MIN_LEN` is set to `4`.

**NOTE:** for `lzss_encode_fast()` is recommended to set `$LZ_MIN_LEN = 5`, which will result in slightly better compression ratio.

## $LZ\_MAX\_LEN

Maximum length of a match in LZ parsing. The value must be an integer greater than or equal to `0`.

By default, `$LZ_MAX_LEN` is set to `258`.

**NOTE:** the functions `lz77_encode()` and `lzb_compress()` will ignore this value and will always use unlimited match lengths.

## $LZ\_MAX\_DIST

Maximum back-reference distance allowed in LZ parsing. Smaller values will result in faster parsing, but lower compression ratio.

By default, the value is unlimited, meaning that arbitrarily large back-references will be generated.

**NOTE:** the function `lzb_compress()` will ignore this value and will always use the value `2**16 - 1` as the maximum back-reference distance.

## $LZ\_MAX\_CHAIN\_LEN

The value of `$LZ_MAX_CHAIN_LEN` controls the amount of recent positions to remember for each matched prefix. A larger value results in better compression, finding longer matches, at the expense of speed.

By default, `$LZ_MAX_CHAIN_LEN` is set to `32`.

**NOTE:** the function `lzss_encode_fast()` will ignore this value, always using a value of `1`.

# HIGH-LEVEL FUNCTIONS

```perl
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

      bwt_compress($string)                # Bzip2-like compression (RLE4+BWT+MTF+ZRLE+Huffman coding)
      bwt_decompress($fh)                  # Inverse of the above method

      bwt_compress_symbolic(\@symbols)     # Bzip2-like compression (RLE4+sBWT+MTF+ZRLE+Huffman coding)
      bwt_decompress_symbolic($fh)         # Inverse of the above method

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
```

# MEDIUM-LEVEL FUNCTIONS

```perl
      deltas(\@ints)                       # Computes the differences between integers
      accumulate(\@deltas)                 # Inverse of the above method

      delta_encode(\@ints)                 # Delta+RLE encoding of an array of integers
      delta_decode($fh)                    # Inverse of the above method

      fibonacci_encode(\@symbols)          # Fibonacci coding of an array of symbols
      fibonacci_decode($fh)                # Inverse of the above method

      elias_gamma_encode(\@symbols)        # Elias Gamma coding method of an array of symbols
      elias_gamma_decode($fh)              # Inverse of the above method

      elias_omega_encode(\@symbols)        # Elias Omega coding method of an array of symbols
      elias_omega_decode($fh)              # Inverse of the above method

      abc_encode(\@symbols)                # Adaptive Binary Concatenation method of an array of symbols
      abc_decode($fh)                      # Inverse of the above method

      obh_encode(\@symbols)                # Offset bits + Huffman coding of an array of symbols
      obh_decode($fh)                      # Inverse of the above method

      bwt_encode($string)                  # Burrows-Wheeler transform
      bwt_decode($bwt, $idx)               # Inverse of Burrows-Wheeler transform

      bwt_encode_symbolic(\@symbols)       # Burrows-Wheeler transform over an array of symbols
      bwt_decode_symbolic(\@bwt, $idx)     # Inverse of symbolic Burrows-Wheeler transform

      mtf_encode(\@symbols)                # Move-to-front transform
      mtf_decode(\@mtf, \@alphabet)        # Inverse of the above method

      encode_alphabet(\@alphabet)          # Encode an alphabet of symbols into a binary string
      decode_alphabet($fh)                 # Inverse of the above method

      frequencies(\@symbols)               # Returns a dictionary with symbol frequencies
      run_length(\@symbols, $max=undef)    # Run-length encoding, returning a 2D array

      rle4_encode(\@symbols, $max=255)     # Run-length encoding with 4 or more consecutive characters
      rle4_decode(\@rle4)                  # Inverse of the above method

      zrle_encode(\@symbols)               # Run-length encoding of zeros
      zrle_decode(\@zrle)                  # Inverse of the above method

      ac_encode(\@symbols)                 # Arithmetic Coding applied on an array of symbols
      ac_decode($bitstring, \%freq)        # Inverse of the above method

      adaptive_ac_encode(\@symbols)               # Adaptive Arithmetic Coding applied on an array of symbols
      adaptive_ac_decode($bitstring, \@alphabet)  # Inverse of the above method

      lzw_encode($string)                  # LZW encoding of a given string
      lzw_decode(\@symbols)                # Inverse of the above method
```

# LOW-LEVEL FUNCTIONS

```perl
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

      string2symbols($string)              # Returns an array-ref of code points
      symbols2string(\@symbols)            # Returns a string, given an array of code points

      read_null_terminated($fh)            # Read a binary string that ends with NULL ("\0")

      binary_vrl_encode($bitstring)        # Binary variable run-length encoding
      binary_vrl_decode($bitstring)        # Binary variable run-length decoding

      bwt_sort($string)                    # Burrows-Wheeler sorting
      bwt_sort_symbolic(\@symbols)         # Burrows-Wheeler sorting, applied on an array of symbols

      huffman_encode(\@symbols, \%dict)    # Huffman encoding
      huffman_decode($bitstring, \%dict)   # Huffman decoding, given a string of bits

      huffman_from_freq(\%freq)            # Create Huffman dictionaries, given an hash of frequencies
      huffman_from_symbols(\@symbols)      # Create Huffman dictionaries, given an array of symbols
      huffman_from_code_lengths(\@lens)    # Create canonical Huffman codes, given an array of code lengths

      make_deflate_tables($max_dist, $max_len) # Returns the DEFLATE tables for distance and length symbols
      find_deflate_index($value, \@table)      # Returns the index in a DEFLATE table, given a numerical value

      lzss_encode($string)                     # LZSS encoding of a string into literals, distances and lengths
      lzss_encode_fast($string)                # Fast-LZSS encoding of a string into literals, distances and lengths
      lzss_decode(\@lits, \@idxs, \@lens)      # Inverse of the above two methods

      deflate_encode(\@lits, \@idxs, \@lens)   # DEFLATE-like encoding of values returned by lzss_encode()
      deflate_decode($fh)                      # Inverse of the above method
```

# INTERFACE FOR HIGH-LEVEL FUNCTIONS

## create\_huffman\_entry

```perl
    my $string = create_huffman_entry(\@symbols);
```

High-level function that generates a Huffman coding block, given an array-ref of symbols.

## decode\_huffman\_entry

```perl
    my $symbols = decode_huffman_entry($fh);
    my $symbols = decode_huffman_entry($string);
```

Inverse of `create_huffman_entry()`.

## create\_ac\_entry

```perl
    my $string = create_ac_entry(\@symbols);
```

High-level function that generates an Arithmetic Coding block, given an array-ref of symbols.

## decode\_ac\_entry

```perl
    my $symbols = decode_ac_entry($fh);
    my $symbols = decode_ac_entry($string);
```

Inverse of `create_ac_entry()`.

## create\_adaptive\_ac\_entry

```perl
    my $string = create_adaptive_ac_entry(\@symbols);
```

High-level function that generates an Adaptive Arithmetic Coding block, given an array-ref of symbols.

## decode\_adaptive\_ac\_entry

```perl
    my $symbols = decode_adaptive_ac_entry($fh);
    my $symbols = decode_adaptive_ac_entry($string);
```

Inverse of `create_adaptive_ac_entry()`.

## lz77\_compress / lz77\_compress\_symbolic

```perl
    # With Huffman coding
    my $string = lz77_compress($data);
    my $string = lz77_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lz77_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lz77_compress($data, \&create_huffman_entry, \&lzss_encode_fast);
```

High-level function that performs LZ77 compression on the provided data, using the pipeline:

    1. lz77_encode
    2. create_huffman_entry(literals)
    3. create_huffman_entry(lengths)
    4. create_huffman_entry(matches)
    5. obh_encode(distances)

The function accepts either a string or an array-ref of symbols as the first argument.

## lz77\_decompress / lz77\_decompress\_symbolic

```perl
    # With Huffman coding
    my $data = lz77_decompress($fh);
    my $data = lz77_decompress($string);

    # With Arithemtic coding
    my $data = lz77_decompress($fh, \&decode_ac_entry);
    my $data = lz77_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lz77_decompress_symbolic($fh);
    my $symbols = lz77_decompress_symbolic($string);
```

Inverse of `lz77_compress()` and `lz77_compress_symbolic`, respectively.

## lzss\_compress / lzss\_compress\_symbolic

```perl
    # With Huffman coding
    my $string = lzss_compress($data);
    my $string = lzss_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lzss_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lzss_compress($data, \&create_huffman_entry, \&lzss_encode_fast);
```

High-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data, using the pipeline:

    1. lzss_encode
    2. deflate_encode

The function accepts either a string or an array-ref of symbols as the first argument.

## lzss\_decompress / lzss\_decompress\_symbolic

```perl
    # With Huffman coding
    my $data = lzss_decompress($fh);
    my $data = lzss_decompress($string);

    # With Arithmetic coding
    my $data = lzss_decompress($fh, \&decode_ac_entry);
    my $data = lzss_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lzss_decompress_symbolic($fh);
    my $symbols = lzss_decompress_symbolic($string);
```

Inverse of `lzss_compress()` and `lzss_compress_symbolic`, respectively.

## lzb\_compress

```perl
    my $string = lzb_compress($data);
    my $string = lzb_compress($data, \&lzss_encode_fast);   # with fast-LZ parsing
```

High-level function that performs byte-oriented LZSS compression, inspired by LZ4.

## lzb\_decompress

```perl
    my $data = lzb_decompress($fh);
    my $data = lzb_decompress($string);
```

Inverse of `lzb_compress()`.

## lzw\_compress

```perl
    my $string = lzw_compress($data);
```

High-level function that performs LZW (Lempel-Ziv-Welch) compression on the provided data, using the pipeline:

    1. lzw_encode
    2. abc_encode

## lzw\_decompress

```perl
    my $data = lzw_decompress($fh);
    my $data = lzw_decompress($string);
```

Performs Lempel-Ziv-Welch (LZW) decompression on the provided string or file-handle. Inverse of `lzw_compress()`.

## bwt\_compress

```perl
    # Using Huffman Coding
    my $string = bwt_compress($data);

    # Using Arithmetic Coding
    my $string = bwt_compress($data, \&create_ac_entry);
```

High-level function that performs Bzip2-like compression on the provided data, using the pipeline:

    1. rle4_encode
    2. bwt_encode
    3. mtf_encode
    4. zrle_encode
    5. create_huffman_entry

## bwt\_decompress

```perl
    # With Huffman coding
    my $data = bwt_decompress($fh);
    my $data = bwt_decompress($string);

    # With Arithmetic coding
    my $data = bwt_decompress($fh, \&decode_ac_entry);
    my $data = bwt_decompress($string, \&decode_ac_entry);
```

Inverse of `bwt_compress()`.

## bwt\_compress\_symbolic

```perl
    # Does Huffman coding
    my $string = bwt_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = bwt_compress_symbolic(\@symbols, \&create_ac_entry);
```

Similar to `bwt_compress()`, except that it accepts an arbitrary array-ref of non-negative integer values as input. It is also a bit slower on large inputs.

## bwt\_decompress\_symbolic

```perl
    # Using Huffman coding
    my $symbols = bwt_decompress_symbolic($fh);
    my $symbols = bwt_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = bwt_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = bwt_decompress_symbolic($string, \&decode_ac_entry);
```

Inverse of `bwt_compress_symbolic()`.

## mrl\_compress / mrl\_compress\_symbolic

```perl
    # Does Huffman coding
    my $enc = mrl_compress($str);
    my $enc = mrl_compress(\@symbols);

    # Does Arithmetic coding
    my $enc = mrl_compress($str, \&create_ac_entry);
    my $enc = mrl_compress(\@symbols, \&create_ac_entry);
```

A fast compression method, using the following pipeline:

    1. mtf_encode
    2. zrle_encode
    3. rle4_encode
    4. create_huffman_entry

It accepts an arbitrary array-ref of non-negative integer values as input.

## mrl\_decompress / mrl\_decompress\_symbolic

```perl
    # With Huffman coding
    my $data = mrl_decompress($fh);
    my $data = mrl_decompress($string);

    # Symbolic, with Huffman coding
    my $symbols = mrl_decompress_symbolic($fh);
    my $symbols = mrl_decompress_symbolic($string);

    # Symbolic, with Arithmetic coding
    my $symbols = mrl_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = mrl_decompress_symbolic($string, \&decode_ac_entry);
```

Inverse of `mrl_decompress()` and `mrl_compress_symbolic()`.

# INTERFACE FOR MEDIUM-LEVEL FUNCTIONS

## frequencies

```perl
    my $freq = frequencies(\@symbols);
```

Returns an hash ref dictionary with frequencies, given an array-ref of symbols.

## deltas

```perl
    my $deltas = deltas(\@integers);
```

Computes the differences between consecutive integers, returning an array.

## accumulate

```perl
    my $integers = accumulate(\@deltas);
```

Inverse of `deltas()`.

## delta\_encode

```perl
    my $string = delta_encode(\@integers);
```

Encodes a sequence of integers (including negative integers) using Delta + Run-length + Elias omega coding, returning a binary string.

Delta encoding calculates the difference between consecutive integers in the sequence and encodes these differences using Elias omega coding. When it's beneficial, runs of identical symbols are collapsed with RLE.

## delta\_decode

```perl
    # Given a file-handle
    my $integers = delta_decode($fh);

    # Given a string
    my $integers = delta_decode($string);
```

Inverse of `delta_encode()`.

## fibonacci\_encode

```perl
    my $string = fibonacci_encode(\@symbols);
```

Encodes a sequence of non-negative integers using Fibonacci coding, returning a binary string.

## fibonacci\_decode

```perl
    # Given a file-handle
    my $symbols = fibonacci_decode($fh);

    # Given a binary string
    my $symbols = fibonacci_decode($string);
```

Inverse of `fibonacci_encode()`.

## elias\_gamma\_encode

```perl
    my $string = elias_gamma_encode(\@symbols);
```

Encodes a sequence of non-negative integers using Elias Gamma coding, returning a binary string.

## elias\_gamma\_decode

```perl
    # Given a file-handle
    my $symbols = elias_gamma_decode($fh);

    # Given a binary string
    my $symbols = elias_gamma_decode($string);
```

Inverse of `elias_gamma_encode()`.

## elias\_omega\_encode

```perl
    my $string = elias_omega_encode(\@symbols);
```

Encodes a sequence of non-negative integers using Elias Omega coding, returning a binary string.

## elias\_omega\_decode

```perl
    # Given a file-handle
    my $symbols = elias_omega_decode($fh);

    # Given a binary string
    my $symbols = elias_omega_decode($string);
```

Inverse of `elias_omega_encode()`.

## abc\_encode

```perl
    my $string = abc_encode(\@symbols);
```

Encodes a sequence of non-negative integers using the Adaptive Binary Concatenation encoding method.

This method is particularly effective in encoding a sequence of integers that are in ascending order or have roughly the same size in binary.

## abc\_decode

```perl
    # Given a file-handle
    my $symbols = abc_decode($fh);

    # Given a binary string
    my $symbols = abc_decode($string);
```

Inverse of `abc_encode()`.

## obh\_encode

```perl
    # With Huffman Coding
    my $string = obh_encode(\@symbols);

    # With Arithmetic Coding
    my $string = obh_encode(\@symbols, \&create_ac_entry);
```

Encodes a sequence of non-negative integers using offset bits and Huffman coding.

This method is particularly effective in encoding a sequence of moderately large random integers, such as the list of distances returned by `lzss_encode()`.

## obh\_decode

```perl
    # Given a file-handle
    my $symbols = obh_decode($fh);                        # Huffman decoding
    my $symbols = obh_decode($fh, \&decode_ac_entry);     # Arithmetic decoding

    # Given a binary string
    my $symbols = obh_decode($string);                    # Huffman decoding
    my $symbols = obh_decode($string, \&decode_ac_entry); # Arithmetic decoding
```

Inverse of `obh_encode()`.

## bwt\_encode

```perl
    my ($bwt, $idx) = bwt_encode($string);
    my ($bwt, $idx) = bwt_encode($string, $lookahead_len);
```

Applies the Burrows-Wheeler Transform (BWT) to a given string.

## bwt\_decode

```perl
    my $string = bwt_decode($bwt, $idx);
```

Reverses the Burrows-Wheeler Transform (BWT) applied to a string.

The function returns the original string.

## bwt\_encode\_symbolic

```perl
    my ($bwt_symbols, $idx) = bwt_encode_symbolic(\@symbols);
```

Applies the Burrows-Wheeler Transform (BWT) to a sequence of symbolic elements.

## bwt\_decode\_symbolic

```perl
    my $symbols = bwt_decode_symbolic(\@bwt_symbols, $idx);
```

Reverses the Burrows-Wheeler Transform (BWT) applied to a sequence of symbolic elements.

## mtf\_encode

```perl
    my $mtf = mtf_encode(\@symbols, \@alphabet);
    my ($mtf, $alphabet) = mtf_encode(\@symbols);
```

Performs Move-To-Front (MTF) encoding on a sequence of symbols.

The function returns the encoded MTF sequence and the sorted list of unique symbols in the input data, representing the alphabet.

Optionally, the alphabet can be provided as a second argument. When two arguments are provided, only the MTF sequence is returned.

## mtf\_decode

```perl
    my $symbols = mtf_decode(\@mtf, \@alphabet);
```

Inverse of `mtf_encode()`.

## encode\_alphabet

```perl
    my $string = encode_alphabet(\@alphabet);
```

Encodes an alphabet of symbols into a binary string.

## decode\_alphabet

```perl
    my $alphabet = decode_alphabet($fh);
    my $alphabet = decode_alphabet($string);
```

Decodes an encoded alphabet, given a file-handle or a binary string, returning an array-ref of symbols. Inverse of `encode_alphabet()`.

## run\_length

```perl
    my $rl = run_length(\@symbols);
    my $rl = run_length(\@symbols, $max_run);
```

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements.

It takes two parameters: `\@symbols`, representing an array of symbols, and `$max_run`, indicating the maximum run length allowed.

The function returns a 2D-array, with pairs: `[symbol, run_length]`, such that the following code reconstructs the `\@symbols` array:

```perl
    my @symbols = map { ($_->[0]) x $_->[1] } @$rl;
```

By default, the maximum run-length is unlimited.

## rle4\_encode

```perl
    my $rle4 = rle4_encode($string);
    my $rle4 = rle4_encode(\@symbols);
    my $rle4 = rle4_encode(\@symbols, $max_run);
```

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements, specifically designed for runs of four or more consecutive symbols.

It takes two parameters: `\@symbols`, representing an array of symbols, and `$max_run`, indicating the maximum run length allowed during encoding.

The function returns the encoded RLE sequence as an array-ref of symbols.

By default, the maximum run-length is limited to `255`.

## rle4\_decode

```perl
    my $symbols = rle4_decode(\@rle4);
    my $symbols = rle4_decode($rle4_string);
```

Inverse of `rle4_encode()`.

## zrle\_encode

```perl
    my $zrle = zrle_encode(\@symbols);
```

Performs Zero-Run-Length Encoding (ZRLE) on a sequence of symbolic elements, returning the encoded ZRLE sequence as an array-ref of symbols.

This function efficiently encodes runs of zeros, but also increments each symbol by `1`.

## zrle\_decode

```perl
    my $symbols = zrle_decode($zrle);
```

Inverse of `zrle_encode()`.

## ac\_encode

```perl
    my ($bitstring, $freq) = ac_encode(\@symbols);
```

Performs Arithmetic Coding on the provided symbols.

It takes a single parameter, `\@symbols`, representing the symbols to be encoded.

The function returns two values: `$bitstring`, which is a string of 1s and 0s, and `$freq`, representing the frequency table used for encoding.

## ac\_decode

```perl
    my $symbols = ac_decode($bits_fh, \%freq);
    my $symbols = ac_decode($bitstring, \%freq);
```

Performs Arithmetic Coding decoding using the provided frequency table and a string of 1s and 0s. Inverse of `ac_encode()`.

It takes two parameters: `$bitstring`, representing a string of 1s and 0s containing the arithmetic coded data, and `\%freq`, representing the frequency table used for encoding.

The function returns the decoded sequence of symbols.

## adaptive\_ac\_encode

```perl
    my ($bitstring, $alphabet) = adaptive_ac_encode(\@symbols);
```

Performs Adaptive Arithmetic Coding on the provided symbols.

It takes a single parameter, `\@symbols`, representing the symbols to be encoded.

The function returns two values: `$bitstring`, which is a string of 1s and 0s, and `$alphabet`, which is an array-ref of distinct sorted symbols.

## adaptive\_ac\_decode

```perl
    my $symbols = adaptive_ac_decode($bits_fh, \@alphabet);
    my $symbols = adaptive_ac_decode($bitstring, \@alphabet);
```

Performs Adaptive Arithmetic Coding decoding using the provided frequency table and a string of 1s and 0s.

It takes two parameters: `$bitstring`, representing a string of 1s and 0s containing the adaptive arithmetic coded data, and `\@alphabet`, representing the array of distinct sorted symbols that appear in the encoded data.

The function returns the decoded sequence of symbols.

## lzw\_encode

```perl
    my $symbols = lzw_encode($string);
```

Performs Lempel-Ziv-Welch (LZW) encoding on the provided string.

It takes a single parameter, `$string`, representing the data to be encoded.

The function returns an array-ref of symbols.

## lzw\_decode

```perl
    my $string = lzw_decode(\@symbols);
```

Performs Lempel-Ziv-Welch (LZW) decoding on the provided symbols. Inverse of `lzw_encode()`.

The function returns the decoded string.

# INTERFACE FOR LOW-LEVEL FUNCTIONS

## read\_bit

```perl
    my $bit = read_bit($fh, \$buffer);
```

Reads a single bit from a file-handle `$fh` (MSB order).

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## read\_bit\_lsb

```perl
    my $bit = read_bit_lsb($fh, \$buffer);
```

Reads a single bit from a file-handle `$fh` (LSB order).

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## read\_bits

```perl
    my $bitstring = read_bits($fh, $bits_len);
```

Reads a specified number of bits (`$bits_len`) from a file-handle (`$fh`) and returns them as a string, in MSB order.

## read\_bits\_lsb

```perl
    my $bitstring = read_bits_lsb($fh, $bits_len);
```

Reads a specified number of bits (`$bits_len`) from a file-handle (`$fh`) and returns them as a string, in LSB order.

## int2bits

```perl
    my $bitstring = int2bits($symbol, $size)
```

Convert a non-negative integer to a bitstring of width `$size`, in MSB order.

## int2bits\_lsb

```perl
    my $bitstring = int2bits_lsb($symbol, $size)
```

Convert a non-negative integer to a bitstring of width `$size`, in LSB order.

## bits2int

```perl
    my $integer = bits2int($fh, $size, \$buffer)
```

Read `$size` bits from file-handle `$fh` and convert them to an integer, in MSB order. Inverse of `int2bits()`.

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## bits2int\_lsb

```perl
    my $integer = bits2int_lsb($fh, $size, \$buffer)
```

Read `$size` bits from file-handle `$fh` and convert them to an integer, in LSB order. Inverse of `int2bits_lsb()`.

The function stores the extra bits inside the `$buffer`, reading one character at a time from the file-handle.

## bytes2int

```perl
    my $integer = bytes2int($fh, $n);
```

Read `$n` bytes from file-handle `$fh` and convert them to an integer, in MSB order.

## bytes2int\_lsb

```perl
    my $integer = bytes2int_lsb($fh, $n);
```

Read `$n` bytes from file-handle `$fh` and convert them to an integer, in LSB order.

## string2symbols

```perl
    my $symbols = string2symbols($string)
```

Returns an array-ref of code points, given a string.

## symbols2string

```perl
    my $string = symbols2string(\@symbols)
```

Returns a string, given an array-ref of code points.

## read\_null\_terminated

```perl
    my $string = read_null_terminated($fh)
```

Read a string from file-handle `$fh` that ends with a NULL character ("\\0").

## binary\_vrl\_encode

```perl
    my $bitstring_enc = binary_vrl_encode($bitstring);
```

Given a string of 1s and 0s, returns back a bitstring of 1s and 0s encoded using variable run-length encoding.

## binary\_vrl\_decode

```perl
    my $bitstring = binary_vrl_decode($bitstring_enc);
```

Given an encoded bitstring, returned by `binary_vrl_encode()`, gives back the decoded string of 1s and 0s.

## bwt\_sort

```perl
    my $indices = bwt_sort($string);
    my $indices = bwt_sort($string, $lookahead_len);
```

Low-level function that sorts the rotations of a given string using the Burrows-Wheeler Transform (BWT) algorithm.

It takes two parameters: `$string`, which is the input string to be transformed, and `$LOOKAHEAD_LEN` (optional), representing the length of look-ahead during sorting.

The function returns an array-ref of indices.

There is probably no need to call this function explicitly. Use `bwt_encode()` instead!

## bwt\_sort\_symbolic

```perl
    my $indices = bwt_sort_symbolic(\@symbols);
```

Low-level function that sorts the rotations of a sequence of symbolic elements using the Burrows-Wheeler Transform (BWT) algorithm.

It takes a single parameter `\@symbols`, which represents the input sequence of symbolic elements. The function returns an array of indices.

There is probably no need to call this function explicitly. Use `bwt_encode_symbolic()` instead!

## huffman\_from\_freq

```perl
    my $dict = huffman_from_freq(\%freq);
    my ($dict, $rev_dict) = huffman_from_freq(\%freq);
```

Low-level function that constructs Huffman prefix codes, based on the frequency of symbols provided in a hash table.

It takes a single parameter, `\%freq`, representing the hash table where keys are symbols, and values are their corresponding frequencies.

The function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

## huffman\_from\_symbols

```perl
    my $dict = huffman_from_symbols(\@symbols);
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);
```

Low-level function that constructs Huffman prefix codes, given an array-ref of symbols.

It takes a single parameter, `\@symbols`, from which it computes the frequency of each symbol and generates the corresponding Huffman prefix codes.

The function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

## huffman\_from\_code\_lengths

```perl
    my $dict = huffman_from_code_lengths(\@code_lengths);
    my ($dict, $rev_dict) = huffman_from_code_lengths(\@code_lengths);
```

Low-level function that constructs a dictionary of canonical prefix codes, given an array of code lengths, as defined in RFC 1951 (Section 3.2.2).

It takes a single parameter, `\@code_lengths`, where entry `$i` in the array corresponds to the code length for symbol `$i`.

The function returns two values: `$dict`, which is the mapping of symbols to Huffman codes, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

## huffman\_encode

```perl
    my $bitstring = huffman_encode(\@symbols, $dict);
```

Low-level function that performs Huffman encoding on a sequence of symbols using a provided dictionary, returned by `huffman_from_freq()`.

It takes two parameters: `\@symbols`, representing the sequence of symbols to be encoded, and `$dict`, representing the Huffman dictionary mapping symbols to their corresponding Huffman codes.

The function returns a concatenated string of 1s and 0s, representing the Huffman-encoded sequence of symbols.

## huffman\_decode

```perl
    my $symbols = huffman_decode($bitstring, $rev_dict);
```

Low-level function that decodes a Huffman-encoded binary string into a sequence of symbols using a provided reverse dictionary.

It takes two parameters: `$bitstring`, representing the Huffman-encoded string of 1s and 0s, as returned by `huffman_encode()`, and `$rev_dict`, representing the reverse dictionary mapping Huffman codes to their corresponding symbols.

The function returns the decoded sequence of symbols as an array-ref.

## lz77\_encode / lz77\_encode\_symbolic

```perl
    my ($literals, $distances, $lengths, $matches) = lz77_encode($string);
    my ($literals, $distances, $lengths, $matches) = lz77_encode(\@symbols);
```

Low-level function that combines LZSS with ideas from the LZ4 method.

The function returns four values:

```perl
    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of literal lengths
    $matches    # array-ref of match lengths
```

The output can be decoded with `lz77_decode()` and `lz77_decode_symbolic()`, respectively.

## lz77\_decode / lz77\_decode\_symbolic

```perl
    my $string  = lz77_decode(\@literals, \@distances, \@lengths, \@matches);
    my $symbols = lz77_decode_symbolic(\@literals, \@distances, \@lengths, \@matches);
```

Low-level function that performs decoding using the provided literals, lengths, matches and distances of matched sub-strings.

Inverse of `lz77_encode()` and `lz77_encode_symbolic()`, respectively.

## lzss\_encode / lzss\_encode\_fast / lzss\_encode\_symbolic / lzss\_encode\_fast\_symbolic

```perl
    # Standard version
    my ($literals, $distances, $lengths) = lzss_encode($data);
    my ($literals, $distances, $lengths) = lzss_encode(\@symbols);

    # Faster version
    my ($literals, $distances, $lengths) = lzss_encode_fast($data);
    my ($literals, $distances, $lengths) = lzss_encode_fast(\@symbols);
```

Low-level function that applies the LZSS (Lempel-Ziv-Storer-Szymanski) algorithm on the provided data.

The function returns three values:

```perl
    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of match lengths
```

The output can be decoded with `lzss_decode()` and `lzss_decode_symbolic`, respectively.

## lzss\_decode / lzss\_decode\_symbolic

    my $string  = lzss_decode(\@literals, \@distances, \@lengths);
    my $symbols = lzss_decode_symbolic(\@literals, \@distances, \@lengths);

Low-level function that decodes the LZSS encoding, using the provided literals, distances, and lengths of matched sub-strings.

Inverse of `lzss_encode()` and `lzss_encode_fast()`.

## deflate\_encode

```perl
    # Returns a binary string
    my $string = deflate_encode(\@literals, \@distances, \@lengths);
    my $string = deflate_encode(\@literals, \@distances, \@lengths, \&create_ac_entry);
```

Low-level function that encodes the results returned by `lzss_encode()` and `lzss_encode_fast()`, using a DEFLATE-like approach, combined with Huffman coding.

## deflate\_decode

```perl
    # Huffman decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh);
    my ($literals, $distances, $lengths) = deflate_decode($string);

    # Arithmetic decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh, \&decode_ac_entry);
    my ($literals, $distances, $lengths) = deflate_decode($string, \&decode_ac_entry);
```

Inverse of `deflate_encode()`.

## make\_deflate\_tables

```perl
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($max_dist, $max_len);
```

Low-level function that returns a list of tables used in encoding the relative back-reference distances and lengths returned by `lzss_encode()` and `lzss_encode_fast()`.

When no arguments are provided:

```perl
    $max_dist = $Compression::Util::LZ_MAX_DIST
    $max_len  = $Compression::Util::LZ_MAX_LEN
```

There is no need to call this function explicitly. Use `deflate_encode()` instead!

## find\_deflate\_index

```perl
    my $index = find_deflate_index($value, $DISTANCE_SYMBOLS);
```

Low-level function that returns the index inside the DEFLATE tables for a given value.

# EXPORT

Each function can be exported individually, as:

```perl
    use Compression::Util qw(bwt_compress);
```

By specifying the **:all** keyword, will export all the exportable functions:

```perl
    use Compression::Util qw(:all);
```

Nothing is exported by default.

# EXAMPLES

The functions can be combined in various ways, easily creating novel compression methods, as illustrated in the following examples.

## Combining LZSS + MRL compression:

```perl
    my $enc = lzss_compress($str, \&mrl_compress_symbolic);
    my $dec = lzss_decompress($enc, \&mrl_decompress_symbolic);
```

## Combining LZ77 + OBH encoding:

```perl
    my $enc = lz77_compress($str, \&obh_encode);
    my $dec = lz77_decompress($enc, \&obh_decode);
```

## Combining LZSS + symbolic BWT compression:

```perl
    my $enc = lzss_compress($str, \&bwt_compress_symbolic);
    my $dec = lzss_decompress($enc, \&bwt_decompress_symbolic);
```

## Combining BWT + symbolic LZSS:

```perl
    my $enc = bwt_compress($str, \&lzss_compress_symbolic);
    my $dec = bwt_decompress($enc, \&lzss_decompress_symbolic);
```

## Combining LZW + Fibonacci encoding:

```perl
    my $enc = lzw_compress($str, \&fibonacci_encode);
    my $dec = lzw_decompress($enc, \&fibonacci_decode);
```

## Combining BWT + symbolic LZ77 + symbolic MRL:

```perl
    my $enc = bwt_compress($str, sub ($s) { lz77_compress_symbolic($s, \&mrl_compress_symbolic) });
    my $dec = bwt_decompress($enc, sub ($s) { lz77_decompress_symbolic($s, \&mrl_decompress_symbolic) });
```

## Combining LZ77 + BWT compression + Fibonacci encoding + Huffman coding + OBH encoding + MRL compression:

```perl
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
```

# SEE ALSO

- Data Compression (Summer 2023) - Lecture 4 - The Unix 'compress' Program:
    * [https://youtube.com/watch?v=1cJL9Va80Pk](https://youtube.com/watch?v=1cJL9Va80Pk)
- Data Compression (Summer 2023) - Lecture 5 - Basic Techniques:
    * [https://youtube.com/watch?v=TdFWb8mL5Gk](https://youtube.com/watch?v=TdFWb8mL5Gk)
- Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip):
    * [https://youtube.com/watch?v=SJPvNi4HrWQ](https://youtube.com/watch?v=SJPvNi4HrWQ)
- Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT):
    * [https://youtube.com/watch?v=rQ7wwh4HRZM](https://youtube.com/watch?v=rQ7wwh4HRZM)
- Data Compression (Summer 2023) - Lecture 13 - BZip2:
    * [https://youtube.com/watch?v=cvoZbBZ3M2A](https://youtube.com/watch?v=cvoZbBZ3M2A)
- Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits:
    * [https://youtube.com/watch?v=EqKbT3QdtOI](https://youtube.com/watch?v=EqKbT3QdtOI)
- Information Retrieval WS 17/18, Lecture 4: Compression, Codes, Entropy:
    * [https://youtube.com/watch?v=A\_F94FV21Ek](https://youtube.com/watch?v=A_F94FV21Ek)
- COMP526 7-5 SS7.4 Run length encoding:
    * [https://youtube.com/watch?v=3jKLjmV1bL8](https://youtube.com/watch?v=3jKLjmV1bL8)
- COMP526 Unit 7-6 2020-03-24 Compression - Move-to-front transform:
    * [https://youtube.com/watch?v=Q2pinaj3i9Y](https://youtube.com/watch?v=Q2pinaj3i9Y)
- Basic arithmetic coder in C++:
    * [https://github.com/billbird/arith32](https://github.com/billbird/arith32)
- My blog post on "Lossless Data Compression":
    * [https://trizenx.blogspot.com/2023/09/lossless-data-compression.html](https://trizenx.blogspot.com/2023/09/lossless-data-compression.html)

# REPOSITORY

- GitHub: [https://github.com/trizen/Compression-Util](https://github.com/trizen/Compression-Util)

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to: [https://github.com/trizen/Compression-Util](https://github.com/trizen/Compression-Util).

# AUTHOR

Daniel "Trizen" Șuteu  `<trizen@cpan.org>`

# ACKNOWLEDGEMENTS

Special thanks to professor Bill Bird for the awesome YouTube lectures on data compression.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.
