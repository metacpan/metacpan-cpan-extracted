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
        print $out_fh bz2_compress($chunk);
    }
}

sub decompress ($fh, $out_fh) {
    while (!eof($fh)) {
        print $out_fh bz2_decompress($fh);
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

This functionality is provided by the function `bz2_compress()`, which can be explicitly implemented as:

```perl
use 5.036;
use List::Util qw(uniq);
use Compression::Util qw(:all);

my $data = do { open my $fh, '<:raw', $^X; local $/; <$fh> };
my $rle4 = rle4_encode([unpack('C*', $data)]);
my ($bwt, $idx) = bwt_encode(pack('C*', @$rle4));

my ($mtf, $alphabet) = mtf_encode([unpack("C*", $bwt)]);
my $rle = zrle_encode($mtf);

open my $out_fh, '>:raw', \my $enc;
print $out_fh pack('N', $idx);
print $out_fh encode_alphabet($alphabet);
create_huffman_entry($rle, $out_fh);

say "Original size  : ", length($data);
say "Compressed size: ", length($enc);

# Decompress the result
bz2_decompress($enc) eq $data or die "decompression error";
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

An input filehandle is denoted by `$fh`, while an output file-handle is denoted by `$out_fh`.

The encoding of input and output file-handles must be set to `:raw`.

# HIGH-LEVEL FUNCTIONS

```perl
      create_huffman_entry(\@symbols)      # Create a Huffman Coding block
      decode_huffman_entry($fh)            # Decode a Huffman Coding block

      create_ac_entry(\@symbols)           # Create an Arithmetic Coding block
      decode_ac_entry($fh)                 # Decode an Arithmetic Coding block

      create_adaptive_ac_entry(\@symbols)  # Create an Adaptive Arithmetic Coding block
      decode_adaptive_ac_entry($fh)        # Decode an Adaptive Arithmetic Coding block

      bz2_compress($string)                # Bzip2-like compression (RLE4+BWT+MTF+ZRLE+Huffman coding)
      bz2_decompress($fh)                  # Inverse of the above method

      bz2_compress_symbolic(\@symbols)     # Bzip2-like compression (RLE4+sBWT+MTF+ZRLE+Huffman coding)
      bz2_decompress_symbolic($fh)         # Inverse of the above method

      lz77_compress($string)               # LZ77 + DEFLATE-like encoding of indices and lengths
      lz77_decompress($fh)                 # Inverse of the above method

      lzss_compress($string)               # LZSS + DEFLATE-like encoding of indices and lengths
      lzss_decompress($fh)                 # Inverse of the above method

      lzhd_compress($string)               # LZ77 + Huffman coding of lengths and literals + OBH for indices
      lzhd_decompress($fh)                 # Inverse of the above method

      lzw_compress($string)                # LZW + abc_encode() compression
      lzw_decompress($fh)                  # Inverse of the above method
```

# MEDIUM-LEVEL FUNCTIONS

```perl
      deltas(\@ints)                       # Computes the differences between integers
      accumulate(\@deltas)                 # Inverse of the above method

      delta_encode(\@ints)                 # Delta+RLE encoding of an array of ints
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
      read_bit($fh, \$buffer)              # Read one bit from file-handle
      read_bits($fh, $len)                 # Read `$len` bits from file-handle

      binary_vrl_encode($bitstring)        # Binary variable run-length encoding
      binary_vrl_decode($bitstring)        # Binary variable run-length decoding

      bwt_sort($string)                    # Burrows-Wheeler sorting
      bwt_sort_symbolic(\@symbols)         # Burrows-Wheeler sorting, applied on an array of symbols

      huffman_encode(\@symbols, \%dict)    # Huffman encoding
      huffman_decode($bitstring, \%dict)   # Huffman decoding, given a string of bits

      huffman_from_freq(\%freq)            # Create Huffman dictionaries, given an hash of frequencies
      huffman_from_symbols(\@symbols)      # Create Huffman dictionaries, given an array of symbols
      huffman_from_code_lengths(\@lens)    # Create canonical Huffman codes, given an array of code lengths

      make_deflate_tables($size)           # Returns the DEFLATE tables for distance and length symbols
      find_deflate_index($value, \@table)  # Returns the index in a DEFLATE table, given a numerical value

      lz77_encode($string)                 # LZ77 compression of a string into literals, indices and lengths
      lzss_encode($string)                 # LZSS compression of a string into literals, indices and lengths
      lz77_decode(\@lits, \@idxs, \@lens)  # Inverse of the above two methods

      deflate_encode(\@lits, \@idxs, \@lens)  # DEFLATE-like encoding of values returned by lzss_encode()
      deflate_decode($fh)                     # Inverse of the above method
```

# INTERFACE FOR HIGH-LEVEL FUNCTIONS

## create\_huffman\_entry

```perl
    create_huffman_entry(\@symbols, $out_fh);        # writes to $out_fh
    my $string = create_huffman_entry(\@symbols);    # returns a binary string
```

High-level function that generates a Huffman coding block.

It takes two parameters: `\@symbols`, which represents the symbols to be encoded, and `$out_fh`, which is optional, and represents the file-handle where to write the result.

When the second parameter is omitted, the function returns a binary string.

## decode\_huffman\_entry

```perl
    my $symbols = decode_huffman_entry($fh);
    my $symbols = decode_huffman_entry($string);
```

Inverse of `create_huffman_entry()`.

## create\_ac\_entry

```perl
    create_ac_entry(\@symbols, $out_fh);        # writes to $out_fh
    my $string = create_ac_entry(\@symbols);    # returns a binary string
```

High-level function that generates an Arithmetic Coding block.

It takes two parameters: `\@symbols`, which represents the symbols to be encoded, and `$out_fh`, which is optional, and represents the file-handle where to write the result.

When the second parameter is omitted, the function returns a binary string.

## decode\_ac\_entry

```perl
    my $symbols = decode_ac_entry($fh);
    my $symbols = decode_ac_entry($string);
```

Inverse of `create_ac_entry()`.

## create\_adaptive\_ac\_entry

```perl
    create_adaptive_ac_entry(\@symbols, $out_fh);        # writes to $out_fh
    my $string = create_adaptive_ac_entry(\@symbols);    # returns a binary string
```

High-level function that generates an Adaptive Arithmetic Coding block.

It takes two parameters: `\@symbols`, which represents the symbols to be encoded, and `$out_fh`, which is optional, and represents the file-handle where to write the result.

When the second parameter is omitted, the function returns a binary string.

## decode\_adaptive\_ac\_entry

```perl
    my $symbols = decode_adaptive_ac_entry($fh);
    my $symbols = decode_adaptive_ac_entry($string);
```

Inverse of `create_adaptive_ac_entry()`.

## lz77\_compress

```perl
    # With Huffman coding
    lz77_compress($data, $out_fh);       # writes to file-handle
    my $string = lz77_compress($data);   # returns a binary string

    # With Arithmetic Coding
    lz77_compress($data, $out_fh, \&create_ac_entry);              # writes to file-handle
    my $string = lz77_compress($data, undef, \&create_ac_entry);   # returns a binary string
```

High-level function that performs LZ77 (Lempel-Ziv 1977) compression on the provided data, using the pipeline:

    1. lz77_encode
    2. deflate_encode

It takes a single parameter, `$data`, representing the data string to be compressed.

## lzss\_compress

```perl
    # With Huffman coding
    lzss_compress($data, $out_fh);       # writes to file-handle
    my $string = lzss_compress($data);   # returns a binary string

    # With Arithmetic Coding
    lzss_compress($data, $out_fh, \&create_ac_entry);              # writes to file-handle
    my $string = lzss_compress($data, undef, \&create_ac_entry);   # returns a binary string
```

High-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data, using the pipeline:

    1. lzss_encode
    2. deflate_encode

It takes a single parameter, `$data`, representing the data string to be compressed.

## lz77\_decompress / lzss\_decompress

```perl
    # Writing to file-handle
    lzss_decompress($fh, $out_fh);
    lzss_decompress($string, $out_fh);

    # Writing to file-handle (does Arithmetic decoding)
    lzss_decompress($fh, $out_fh, \&decode_ac_entry);
    lzss_decompress($string, $out_fh, \&decode_ac_entry);

    # Returning the results
    my $data = lzss_decompress($fh);
    my $data = lzss_decompress($string);

    # Returning the results (does Arithmetic decoding)
    my $data = lzss_decompress($fh, undef, \&decode_ac_entry);
    my $data = lzss_decompress($string, undef, \&decode_ac_entry);
```

Inverse of `lzss_compress()` and `lz77_compress()`.

## lzhd\_compress

```perl
    # With Huffman coding
    lzhd_compress($data, $out_fh);       # writes to file-handle
    my $string = lzhd_compress($data);   # returns a binary string

    # With Arithmetic Coding
    lzhd_compress($data, $out_fh, \&create_ac_entry);              # writes to file-handle
    my $string = lzhd_compress($data, undef, \&create_ac_entry);   # returns a binary string
```

High-level function that performs LZ77 (Lempel-Ziv 1977) compression on the provided data, using the pipeline:

    1. lz77_encode
    2. create_huffman_entry(literals)
    3. create_huffman_entry(lengths)
    4. obh_encode(indices)

It takes a single parameter, `$data`, representing the data string to be compressed.

## lzhd\_decompress

```perl
    # Writing to file-handle
    lzhd_decompress($fh, $out_fh);
    lzhd_decompress($string, $out_fh);

    # Writing to file-handle (does Arithmetic decoding)
    lzhd_decompress($fh, $out_fh, \&decode_ac_entry);
    lzhd_decompress($string, $out_fh, \&decode_ac_entry);

    # Returning the results
    my $data = lzhd_decompress($fh);
    my $data = lzhd_decompress($string);

    # Returning the results (does Arithmetic decoding)
    my $data = lzhd_decompress($fh, undef, \&decode_ac_entry);
    my $data = lzhd_decompress($string, undef, \&decode_ac_entry);
```

Inverse of `lzhd_compress()`.

## lzw\_compress

```perl
    lzw_compress($data, $out_fh);       # writes to file-handle
    my $string = lzw_compress($data);   # returns a binary string
```

High-level function that performs LZW (Lempel-Ziv-Welch) compression on the provided data, using the pipeline:

    1. lzw_encode
    2. abc_encode

It takes a single parameter, `$data`, representing the data string to be compressed.

## lzw\_decompress

```perl
    # Writing to filehandle
    lzw_decompress($fh, $out_fh);
    lzw_decompress($string, $out_fh);

    # Returning the results
    my $data = lzw_decompress($fh);
    my $data = lzw_decompress($string);
```

Performs Lempel-Ziv-Welch (LZW) decompression on the provided string or file-handle. Inverse of `lzw_compress()`.

## bz2\_compress

```perl
    # Using Huffman Coding
    bz2_compress($data, $out_fh);        # writes to file-handle
    my $string = bz2_compress($data);    # returns a binary string

    # Using Arithmetic Coding
    bz2_compress($data, $out_fh, \&create_ac_entry);               # writes to file-handle
    my $string = bz2_compress($data, undef, \&create_ac_entry);    # returns a binary string
```

High-level function that performs Bzip2-like compression on the provided data, using the pipeline:

    1. rle4_encode
    2. bwt_encode
    3. mtf_encode
    4. zrle_encode
    5. create_huffman_entry

It takes a parameter string, `$data`, representing the data to be compressed.

The function returns a binary string representing the compressed data.

When the additional optional argument, `$out_fh`, is provided, the compressed data is written to it.

## bz2\_decompress

```perl
    # Writes to file-handle
    bz2_decompress($fh, $out_fh);
    bz2_decompress($string, $out_fh);

    # Writes to file-handle (does Arithmetic decoding)
    bz2_decompress($fh, $out_fh, \&decode_ac_entry);
    bz2_decompress($string, $out_fh, \&decode_ac_entry);

    # Returns the data
    my $data = bz2_decompress($fh);
    my $data = bz2_decompress($string);

    # Returns the data (does Arithmetic decoding)
    my $data = bz2_decompress($fh, undef, \&decode_ac_entry);
    my $data = bz2_decompress($string, undef, \&decode_ac_entry);
```

Inverse of `bz2_compress()`.

## bz2\_compress\_symbolic

```perl
    # Does Huffman coding
    bz2_compress_symbolic(\@symbols, $out_fh);      # writes to file-handle
    my $string = bz2_compress_symbolic(\@symbols);  # returns a binary string

    # Does Arithmetic coding
    bz2_compress_symbolic(\@symbols, $out_fh, \&create_ac_entry);             # writes to file-handle
    my $string = bz2_compress_symbolic(\@symbols, undef, \&create_ac_entry);  # returns a binary string
```

Similar to `bz2_compress()`, except that it accepts an arbitrary array-ref of non-negative integer symbols as input. It is also a bit slower on large inputs.

## bz2\_decompress\_symbolic

```perl
    # Using Huffman coding
    my $symbols = bz2_decompress_symbolic($fh);
    my $symbols = bz2_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = bz2_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = bz2_decompress_symbolic($string, \&decode_ac_entry);
```

Inverse of `bz2_compress_symbolic()`.

# INTERFACE FOR MEDIUM-LEVEL FUNCTIONS

## frequencies

```perl
    my $freq = frequencies(\@symbols);
```

Returns an hash ref dictionary with frequencies, given an array of symbols.

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

Delta encoding calculates the difference between consecutive integers in the sequence and encodes these differences using Elias omega coding. When it's beneficial, runs of identitical symbols are collapsed with RLE.

It takes two parameters: `\@integers`, representing the sequence of arbitrary integers to be encoded, and an optional parameter which defaults to `0`. If the second parameter is set to a true value, double Elias omega coding is performed, which results in better compression for very large integers.

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

This method is particularly effective in encoding a sequence of integers that are in ascending order.

## abc\_decode

```perl
    # Given a filehandle
    my $symbols = abc_decode($fh);

    # Given a binary string
    my $symbols = abc_decode($string);
```

Inverse of `abc_encode()`.

## obh\_encode

```perl
    # With Huffman Coding
    my $string = obh_encode(\@symbols);

    # With Arithemtic Coding
    my $string = obh_encode(\@symbols, \&create_ac_entry);
```

Encodes a sequence of non-negative integers using offset bits and Huffman coding.

This method is particularly effective in encoding a sequence of moderately large random integers, such as the list of indices returned by `lz77_encode()`.

## obh\_decode

```perl
    # Given a filehandle
    my $symbols = obh_decode($fh);                        # Huffman decoding
    my $symbols = obh_decode($fh, \&decode_ac_entry);     # Arithemtic decoding

    # Given a binary string
    my $symbols = obh_decode($string);                    # Huffman decoding
    my $symbols = obh_decode($string, \&decode_ac_entry); # Arithemtic decoding
```

Inverse of `obh_encode()`.

## bwt\_encode

```perl
    my ($bwt, $idx) = bwt_encode($string);
    my ($bwt, $idx) = bwt_encode($string, $lookahead_len);
```

Applies the Burrows-Wheeler Transform (BWT) to a given string.

It returns two values: `$bwt`, which represents the transformed string, and `$idx`, which holds the index of the original string in the sorted list of rotations.

It takes an optional argument `$lookahead_len`, which defaults to `128`, representing the length of look-ahead during sorting.

## bwt\_decode

```perl
    my $string = bwt_decode($bwt, $idx);
```

Reverses the Burrows-Wheeler Transform (BWT) applied to a string.

It takes two parameters: `$bwt`, which is the transformed string, and `$idx`, which represents the index of the original string in the sorted list of rotations.

The function returns the original string.

## bwt\_encode\_symbolic

```perl
    my ($bwt_symbols, $idx) = bwt_encode_symbolic(\@symbols);
```

Applies the Burrows-Wheeler Transform (BWT) to a sequence of symbolic elements.

It takes a single parameter `\@symbols`, which represents the sequence of numerical symbols to be transformed.

The function returns two elements: `$bwt_symbols`, which represents the transformed symbolic sequence, and `$idx`, the index of the original sequence in the sorted list of rotations.

## bwt\_decode\_symbolic

```perl
    my $symbols = bwt_decode_symbolic(\@bwt_symbols, $idx);
```

Reverses the Burrows-Wheeler Transform (BWT) applied to a sequence of symbolic elements.

It takes two parameters: `\@bwt_symbols`, which represents the transformed symbolic sequence, and `$idx`, the index of the original sequence in the sorted list of rotations.

The function returns the original sequence of symbolic elements.

## mtf\_encode

```perl
    my $mtf = mtf_encode(\@symbols, \@alphabet);
    my ($mtf, $alphabet) = mtf_encode(\@symbols);
```

Performs Move-To-Front (MTF) encoding on a sequence of symbols.

It takes one parameter: `\@symbols`, representing the sequence of symbols to be encoded.

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

Efficienlty encodes an alphabet of symbols into a binary string.

## decode\_alphabet

```perl
    my $alphabet = decode_alphabet($fh);
    my $alphabet = decode_alphabet($string);
```

Decodes an encoded alphabet, given a file-handle or a binary string, returning an array of symbols. Inverse of `encode_alphabet()`.

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
    my $rle4 = rle4_encode(\@symbols);
    my $rle4 = rle4_encode(\@symbols, $max_run);
```

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements, specifically designed for runs of four or more consecutive symbols.

It takes two parameters: `\@symbols`, representing an array of symbols, and `$max_run`, indicating the maximum run length allowed during encoding.

The function returns the encoded RLE sequence as an array-ref of symbols.

By default, the maximum run-length is limited to `255`.

## rle4\_decode

```perl
    my $symbols = rle4_decode($rle4);
```

Inverse of `rle4_encode()`.

## zrle\_encode

```perl
    my $zrle = zrle_encode(\@symbols);
```

Performs Zero-Run-Length Encoding (ZRLE) on a sequence of symbolic elements.

It takes a single parameter `\@symbols`, representing the sequence of symbols to be encoded, and returns the encoded ZRLE sequence as an array-ref of symbols.

This function efficiently encodes only runs of zeros, but also increments each symbol by `1`.

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

It takes a single parameter, `$string`, representing the data to be compressed. The function returns the encoded symbols.

## lzw\_decode

```perl
    my $string = lzw_decode(\@symbols);
```

Performs Lempel-Ziv-Welch (LZW) decoding on the provided symbols. Inverse of `lzw_encode()`.

It takes a single parameter, `\@symbols`, representing the encoded symbols to be decompressed. The function returns the decoded string.

# INTERFACE FOR LOW-LEVEL FUNCTIONS

## read\_bit

```perl
    my $bit = read_bit($fh, \$buffer);
```

Reads a single bit from a file-handle `$fh`.

The function stores the extra bits inside the `$buffer`, reading one character at a time from the filehandle.

## read\_bits

```perl
    my $bitstring = read_bits($fh, $bits_len);
```

Reads a specified number of bits (`$bits_len`) from a file-handle (`$fh`) and returns them as a string.

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
    my ($dict, $rev_dict) = huffman_from_freq(\%freq);
```

Low-level function that constructs Huffman prefix codes, based on the frequency of symbols provided in a hash table.

It takes a single parameter, `\%freq`, representing the hash table where keys are symbols, and values are their corresponding frequencies.

The function returns two values: `$dict`, which represents the constructed Huffman dictionary, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

## huffman\_from\_symbols

```perl
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);
```

Low-level function that constructs Huffman prefix codes, given an array of symbols.

It takes a single parameter, `\@symbols`. Interanlly, it computes the frequency of each symbols and generates the Huffman prefix codes.

The function returns two values: `$dict`, which represents the constructed Huffman dictionary, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

## huffman\_from\_code\_lengths

```perl
    my ($dict, $rev_dict) = huffman_from_code_lengths(\@code_lengths);
```

Low-level function that constructs a dictionary of canonical prefix codes, given an array of code lengths, as defined in RFC 1951 (Section 3.2.2).

It takes a single parameter, `\@code_lengths`, where entry `$i` in the array corresponds to the code length for symbol `$i`.

The function returns two values: `$dict`, which represents the constructed Huffman dictionary, and `$rev_dict`, which holds the reverse mapping of Huffman codes to symbols.

## huffman\_encode

```perl
    my $bits = huffman_encode(\@symbols, $dict);
```

Low-level function that performs Huffman encoding on a sequence of symbols using a provided dictionary, returned by `huffman_from_freq()`.

It takes two parameters: `\@symbols`, representing the sequence of symbols to be encoded, and `$dict`, representing the Huffman dictionary mapping symbols to their corresponding Huffman codes.

The function returns a concatenated string of 1s and 0s, representing the Huffman-encoded sequence of symbols.

## huffman\_decode

```perl
    my $symbols = huffman_decode($bits, $rev_dict);
```

Low-level function that decodes a Huffman-encoded binary string into a sequence of symbols using a provided reverse dictionary.

It takes two parameters: `$bits`, representing the Huffman-encoded string of 1s and 0s, as returned by `huffman_encode()`, and `$rev_dict`, representing the reverse dictionary mapping Huffman codes to their corresponding symbols.

The function returns the decoded sequence of symbols as an array-ref.

## lzss\_encode

```perl
    my ($literals, $indices, $lengths) = lzss_encode($data);
```

Low-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data.

It takes a single parameter, `$data`, representing the data string to be compressed.

The function returns three values: `$literals`, which is an array-ref of uncompressed bytes, `$indices`, which contains the indices of the back-references, and `$lengths`, which holds the lengths of the matched sub-strings.

A back-reference is returned only when it's beneficial (i.e.: when it may not inflate the data). Otherwise, the corresponding index and length are both set to `0`.

The output can be decompressed with `lz77_decode()`.

## lz77\_encode

```perl
    my ($literals, $indices, $lengths) = lz77_encode($data);
```

Low-level function that performs LZ77 (Lempel-Ziv 1977) compression on the provided data.

It takes a single parameter, `$data`, representing the data string to be compressed.

The function returns three values: `$literals`, which is an array-ref of uncompressed bytes, `$indices`, which contains the indices of the matched sub-strings, and `$lengths`, which holds the lengths of the matched sub-strings.

Lengths are limited to `255`.

## lz77\_decode / lzss\_decode

```perl
    my $data = lz77_decode($literals, $indices, $lengths);
    my $data = lzss_decode($literals, $indices, $lengths);
```

Low-level function that performs LZ77 (Lempel-Ziv 1977) decompression using the provided literals, indices, and lengths of matched sub-strings.

It takes three parameters: `$literals`, representing the array-ref of uncompressed bytes, `$indices`, containing the indices of the matched sub-strings, and `$lengths`, holding the lengths of the matched sub-strings.

The function returns the decompressed data as a string.

## deflate\_encode

```perl
    # Returns a binary string
    my $string = deflate_encode(\@literals, \@distances, \@lengths);
    my $string = deflate_encode(\@literals, \@distances, \@lengths, \&create_ac_entry);
```

Low-level function that encodes the results returned by `lz77_encode()` and `lzss_encode()`, using a DEFLATE-like approach, combined with Huffman coding.

An optional argument can be provided as `\&create_ac_entry` to use Arithmetic Coding instead of Huffman coding. The default value is `\&create_huffman_entry`.

## deflate\_decode

```perl
    # Huffman decoding
    my ($literals, $indices, $lengths) = deflate_decode($fh);
    my ($literals, $indices, $lengths) = deflate_decode($string);

    # Arithmetic decoding
    my ($literals, $indices, $lengths) = deflate_decode($fh, \&decode_ac_entry);
    my ($literals, $indices, $lengths) = deflate_decode($string, \&decode_ac_entry);
```

Inverse of `deflate_encode()`.

## make\_deflate\_tables

```perl
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($size);
```

Low-level function that returns a list of tables used in encoding the indices and lengths returned by `lz77_encode()` and `lzss_encode()`.

There is no need to call this function explicitly. Use `deflate_encode()` instead!

## find\_deflate\_index

```perl
    my $index = find_deflate_index($value, $DISTANCE_SYMBOLS);
```

Low-level function that returns the index inside the DEFLATE tables for a given value.

# EXPORT

Each function can be exported individually, as:

```perl
    use Compression::Util qw(bz2_compress);
```

By specifying the **:all** keyword, will export all the exportable functions:

```perl
    use Compression::Util qw(:all);
```

Nothing is exported by default.

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
