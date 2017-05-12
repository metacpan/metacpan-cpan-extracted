# Copyright (c) 2017 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

package Compress::Zopfli;

our $VERSION = "0.0.1";

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	compress
	ZOPFLI_FORMAT_GZIP
	ZOPFLI_FORMAT_ZLIB
	ZOPFLI_FORMAT_DEFLATE
);

require XSLoader;

XSLoader::load('Compress::Zopfli', $VERSION);

1;
__END__

=head1 NAME

Compress::Zopfli - Interface to Google Zopfli Compression Algorithm

=head1 SYNOPSIS

    use Compress::Zopfli;
    $gz = compress($input, ZOPFLI_FORMAT_GZIP, {
        iterations => 15,
        blocksplitting => 1,
        blocksplittingmax => 15,
    });

=head1 DESCRIPTION

The I<Compress::Zopfli> module provides a Perl interface to the I<zopfli>
compression library. The zopfli library is bundled with I<Compress::Zopfli>
, so you don't need the I<zopfli> library installed on your system.

The I<zopfli> library only contains one single compression function, which
is directly available via I<Compress::Zopfli>. It supports three different
compression variations:

- I<ZOPFLI_FORMAT_GZIP>: RFC 1952
- I<ZOPFLI_FORMAT_ZLIB>: RFC 1950
- I<ZOPFLI_FORMAT_DEFLATE>: RFC 1951

The constants are exported by default.

=head1 COMPRESS

The I<zopfli> library can only compress, not decompress. Existing zlib or
deflate libraries can decompress the data, i.e. I<IO::Compress>.

=head2 B<($compressed) = compress( $input, I<ZOPFLI_FORMAT>, [OPTIONS] ] )>

This is the only function provided by I<Compress::Zopfli>. The input must
be a string. The underlying function does not seem to support any streaming
interface.

=head1 OPTIONS

Options map directly to the I<zopfli> low-level function. Must be a hash
reference (i.e. anonymous hash) and supports the following options:

=over 5

=item B<iterations>

Maximum amount of times to rerun forward and backward pass to optimize LZ77
compression cost. Good values: 10, 15 for small files, 5 for files over
several MB in size or it will be too slow. Default: 15

=item B<blocksplitting>

If true, splits the data in multiple deflate blocks with optimal choice for
the block boundaries. Block splitting gives better compression. Default: on.

=item B<blocksplittingmax>

Maximum amount of blocks to split into (0 for unlimited, but this can give
extreme results that hurt compression on some files). Default value: 15.

=back

=head1 ALIASES

You probably only want to use a certain compression type. For that this
module also includes some convenient module aliases:

- I<Compress::Zopfli::GZIP>
- I<Compress::Zopfli::ZLIB>
- I<Compress::Zopfli::Deflate>

They export one B<compress> function without the I<ZOPFLI_FORMAT> option.

    use Compress::Zopfli::Deflate;
    compress $input, { iterations: 20 };

=head1 CONSTANTS

All the I<zopfli> constants are automatically imported when you make use
of I<Compress::Zopfli>. See L</DESCRIPTION> for a complete list.

=head1 AUTHOR

The I<Compress::Zopfli> module was written by Marcel Greter,
F<perl-zopfli@ocbnet.ch>. The latest copy of the module can be found on
CPAN in F<modules/by-module/Compress/Compress-Zopfli-x.x.tar.gz>.

The primary site for the I<zopfli> compression library is
F<https://github.com/google/zopfli>.

=head1 MODIFICATION HISTORY

See the Changes file.