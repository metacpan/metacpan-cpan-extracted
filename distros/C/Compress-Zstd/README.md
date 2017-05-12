[![Build Status](https://travis-ci.org/spiritloose/Compress-Zstd.svg?branch=master)](https://travis-ci.org/spiritloose/Compress-Zstd)
# NAME

Compress::Zstd - Perl interface to the Zstd (Zstandard) (de)compressor

# SYNOPSIS

    use Compress::Zstd;

    my $compressed = compress($bytes);
    my $decompressed = decompress($compressed);

# DESCRIPTION

The Compress::Zstd module provides an interface to the Zstd (de)compressor.

# FUNCTIONS

## compress($source \[, $level\])

Compresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error undef is returned.

## compress\_mt($source, $num\_threads \[, $level\])

Multi-threaded version of the `compress` function.

Note that this function uses experimental API of Zstandard.

## decompress($source)

## uncompress($source)

Decompresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error (in case of corrupted data) undef is returned.

# CONSTANTS

## ZSTD\_VERSION\_NUMBER

## ZSTD\_VERSION\_STRING

## ZSTD\_MAX\_CLEVEL

# SEE ALSO

[http://www.zstd.net/](http://www.zstd.net/)

# LICENSE

    Copyright (c) 2016, Jiro Nishiguchi
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

Zstandard by Facebook, Inc.
