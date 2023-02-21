[![Actions Status](https://github.com/pmqs/Compress-Stream-Zstd/workflows/Linux%20build/badge.svg)](https://github.com/pmqs/Compress-Stream-Zstd/actions) [![Actions Status](https://github.com/pmqs/Compress-Stream-Zstd/workflows/MacOS%20build/badge.svg)](https://github.com/pmqs/Compress-Stream-Zstd/actions) [![Actions Status](https://github.com/pmqs/Compress-Stream-Zstd/workflows/Windows%20build/badge.svg)](https://github.com/pmqs/Compress-Stream-Zstd/actions) [![Build Status](https://travis-ci.org/pmqs/Compress-Stream-Zstd.svg?branch=master)](https://travis-ci.org/pmqs/Compress-Stream-Zstd)
# NAME

Compress::Stream::Zstd - Perl interface to the Zstd (Zstandard) (de)compressor

# NOTE

This module is a fork of [Compress-Zstd](https://github.com/spiritloose/Compress-Zstd).
It contains a few changes to make streaming compression/uncompression more robust.
The only reason for this fork is to allow the module to work with \`IO-Compress-Zstd\`.
The hope is that the changes made here can be merged back upstream and this module can be retired.

# SYNOPSIS

    use Compress::Stream::Zstd;

    my $compressed = compress($bytes);
    my $decompressed = decompress($compressed);

# DESCRIPTION

The Compress::Stream::Zstd module provides an interface to the Zstd (de)compressor.

# FUNCTIONS

## compress($source \[, $level\])

Compresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error undef is returned.

## decompress($source)

## uncompress($source)

Decompresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error (in case of corrupted data) undef is returned.

# CONSTANTS

## ZSTD\_VERSION\_NUMBER

## ZSTD\_VERSION\_STRING

## ZSTD\_MAX\_CLEVEL

## ZSTD\_MIN\_CLEVEL

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

Some streaming enhancement by Paul Marquess  <pmqs@cpan.org>

Zstandard by Facebook, Inc.
