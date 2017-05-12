# NAME

Compress::Zopfli - Interface to Google Zopfli Compression Algorithm

# SYNOPSIS

    use Compress::Zopfli;
    $gz = compress($input, ZOPFLI_FORMAT_GZIP, {
        iterations => 15,
        blocksplitting => 1,
        blocksplittingmax => 15,
    });

# DESCRIPTION

The _Compress::Zopfli_ module provides a Perl interface to the _zopfli_
compression library. The zopfli library is bundled with _Compress::Zopfli_
, so you don't need the _zopfli_ library installed on your system.

The _zopfli_ library only contains one sin	le compression function, which
is directly available via _Compress::Zopfli_. It supports three different
compression variations:

\- _ZOPFLI\_FORMAT\_GZIP_: RFC 1952
\- _ZOPFLI\_FORMAT\_ZLIB_: RFC 1950
\- _ZOPFLI\_FORMAT\_DEFLATE_: RFC 1951

The constants are exported by default.

# COMPRESS

The _zopfli_ library can only compress, not decompress. Existing zlib or
deflate libraries can decompress the data, i.e. _IO::Compress_.

## **($compressed) = compress( $input, _ZOPFLI\_FORMAT_, \[OPTIONS\] \] )**

This is the only function provided by _Compress::Zopfli_. The input must
be a string. The underlying function does not seem to support any streaming
interface.

# OPTIONS

Options map directly to the _zopfli_ low-level function. Must be a hash
reference (i.e. anonymous hash) and supports the following options:

- **iterations**

    Maximum amount of times to rerun forward and backward pass to optimize LZ77
    compression cost. Good values: 10, 15 for small files, 5 for files over
    several MB in size or it will be too slow. Default: 15

- **blocksplitting**

    If true, splits the data in multiple deflate blocks with optimal choice for
    the block boundaries. Block splitting gives better compression. Default: on.

- **blocksplittingmax**

    Maximum amount of blocks to split into (0 for unlimited, but this can give
    extreme results that hurt compression on some files). Default value: 15.

# ALIASES

You probably only want to use a certain compression type. For that this
module also includes some convenient module aliases:

\- _Compress::Zopfli::GZIP_
\- _Compress::Zopfli::ZLIB_
\- _Compress::Zopfli::Deflate_

They export one **compress** function without the _ZOPFLI\_FORMAT_ option.

    use Compress::Zopfli::Deflate;
    compress $input, { iterations: 20 };

# CONSTANTS

All the _zopfli_ constants are automatically imported when you make use
of _Compress::Zopfli_. See ["DESCRIPTION"](#description) for a complete list.

# AUTHOR

The _Compress::Zopfli_ module was written by Marcel Greter,
`perl-zopfli@ocbnet.ch`. The latest copy of the module can be found on
CPAN in `modules/by-module/Compress/Compress-Zopfli-x.x.tar.gz`.

The primary site for the _zopfli_ compression library is
`https://github.com/google/zopfli`.

# MODIFICATION HISTORY

See the Changes file.
