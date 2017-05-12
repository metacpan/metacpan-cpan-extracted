Compress::Zopfli
================

**Perl Bindings for Google [Zopfli][1] Compression Algorithm**

[![Build Status](https://travis-ci.org/mgreter/perl-zopfli.svg?branch=master)][2]
[![CPAN version](https://badge.fury.io/pl/Compress-Zopfli.svg)][3]

[1]: https://github.com/google/zopfli
[2]: https://travis-ci.org/mgreter/perl-zopfli
[3]: http://badge.fury.io/pl/Compress-Zopfli

# SYNOPSIS

```perl
use Compress::Zopfli;
$gz = compress($input, ZOPFLI_FORMAT_GZIP, {
    iterations => 15,
    blocksplitting => 1,
    blocksplittingmax => 15,
});
```

# DESCRIPTION

The `Compress::Zopfli` module provides a Perl interface to the `zopfli`
compression library. The zopfli library is bundled with `Compress::Zopfli`
, so you don't need the `zopfli` library installed on your system.

The `zopfli` library only contains one single compression function, which
is directly available via `Compress::Zopfli`. It supports three different
compression variations. See ["CONSTANTS"](#constants) for a complete list.

# COMPRESS

The `zopfli` library can only compress, not decompress. Existing zlib or
deflate libraries can decompress the data, i.e. `IO::Compress`.

## `$compressed = compress( $input, ZOPFLI_FORMAT, \%opts )`

This is the only function provided by `Compress::Zopfli`. The input must
be a string, as the underlying function does not seem to support any streaming
interface. More convenient APIs may be implemented on top.

# OPTIONS

Options map directly to the `zopfli` low-level function. Must be a hash
reference (i.e. anonymous hash) and supports the following options:

- `iterations`

    Maximum amount of times to rerun forward and backward pass to optimize LZ77
    compression cost. Good values: 10, 15 for small files, 5 for files over
    several MB in size or it will be too slow. Default: 15

- `blocksplitting`

    If true, splits the data in multiple deflate blocks with optimal choice for
    the block boundaries. Block splitting gives better compression. Default: on.

- `blocksplittingmax`

    Maximum amount of blocks to split into (0 for unlimited, but this can give
    extreme results that hurt compression on some files). Default value: 15.

# ALIASES

You probably only want to use a certain compression type. Use one of
the module aliases to avoid passing the **ZOPFLI_FORMAT**:

- `Compress::Zopfli::GZIP`
- `Compress::Zopfli::ZLIB`
- `Compress::Zopfli::Deflate`

They export one `compress` function without the **ZOPFLI_FORMAT** option.

```perl
use Compress::Zopfli::Deflate;
compress $input, { iterations: 20 };
```

# CONSTANTS

All the `zopfli` constants are automatically imported when you make use
of `Compress::Zopfli`.

- `ZOPFLI_FORMAT_GZIP`: RFC 1952
- `ZOPFLI_FORMAT_ZLIB`: RFC 1950
- `ZOPFLI_FORMAT_DEFLATE`: RFC 1951

# AUTHOR

- [2017 Marcel Greter][4]

[4]: https://github.com/mgreter

# MODIFICATION HISTORY

See the [Changes][5] file.

[5]: ./Changes
