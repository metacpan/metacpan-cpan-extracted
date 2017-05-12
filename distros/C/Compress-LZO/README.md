# NAME

Compress::LZO

# VERSION

version 1.09

# SYNOPSIS

    use Compress::LZO;

    $dest = Compress::LZO::compress($source, [$level]);
    $dest = Compress::LZO::decompress($source);
    $dest = Compress::LZO::optimize($source);

    $crc = Compress::LZO::adler32($buffer [,$crc]);
    $crc = Compress::LZO::crc32($buffer [,$crc]);

    LZO_VERSION, LZO_VERSION_STRING, LZO_VERSION_DATE

# DESCRIPTION

The _Compress::LZO_ module provides a Perl interface to the _LZO_
compression library (see ["AUTHOR"](#author) for details about where to get
_LZO_). A relevant subset of the functionality provided by _LZO_
is available in _Compress::LZO_.

All string parameters can either be a scalar or a scalar reference.

# NAME

Compress::LZO - Interface to the LZO compression library

# COMPRESSION FUNCTIONS

$dest = Compress::LZO::compress($string)

Compress a string using the default compression level, returning a string
containing compressed data.

$dest = Compress::LZO::compress($string, $level)

Compress string, using the chosen compression level (either 1 or 9).
Return a string containing the compressed data.

If the string is not compressible, _undef_ is returned.

# DECOMPRESSION FUNCTIONS

$dest = Compress::LZO::decompress($string)

Decompress the data in string, returning a string containing the
decompressed data.

On error (in case of corrupted data) _undef_ is returned.

# OPTIMIZATION FUNCTIONS

$dest = Compress::LZO::optimize($string)

Optimize the representation of the compressed data, returning a
string containing the compressed data.

On error _undef_ is returned.

# CHECKSUM FUNCTIONS

Two functions are provided by _LZO_ to calculate a checksum. For the
Perl interface the order of the two parameters in both functions has
been reversed. This allows both running checksums and one off
calculations to be done.

    $crc = Compress::LZO::adler32($string [,$initialAdler]);
    $crc = Compress::LZO::crc32($string [,$initialCrc]);

# AUTHOR

The _Compress::LZO_ module was written by Markus F.X.J. Oberhumer
`markus@oberhumer.com`.
The latest copy of the module should also be found on CPAN in
`modules/by-module/Compress/Compress-LZO-x.y.tar.gz`.

The _LZO_ compression library was written by Markus F.X.J. Oberhumer
`markus@oberhumer.com`.
It is available from the LZO home page at
`http://www.oberhumer.com/opensource/lzo/`.

The _LZO_ library and algorithms
are Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001, 2002 by
Markus Franz Xaver Johannes Oberhumer `markus@oberhumer.com`.
All Rights Reserved.

# MODIFICATION HISTORY

1.08  2002-08-29  Updated for Perl 5.8.0.

1.00  1998-08-22  First public release of _Compress::LZO_.

# AUTHOR

Markus Franz Xaver Johannes Oberhumer <markus@oberhumer.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002 by Markus Franz Xaver Johannes Oberhumer.

This is free software, licensed under:

    The GNU General Public License, Version 2, June 1991
