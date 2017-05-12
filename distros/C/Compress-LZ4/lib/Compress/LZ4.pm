package Compress::LZ4;

use strict;
use warnings;

use Exporter qw(import);
use XSLoader;

our $VERSION    = '0.25';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

our @EXPORT = qw(
    compress compress_hc decompress uncompress
    lz4_compress lz4_compress_hc lz4_decompress lz4_uncompress
);


1;

__END__

=head1 NAME

Compress::LZ4 - Perl interface to the LZ4 (de)compressor

=head1 SYNOPSIS

    use Compress::LZ4;

    my $compressed = compress($bytes);
    my $decompressed = decompress($compressed);

=head1 DESCRIPTION

The C<Compress::LZ4> module provides an interface to the LZ4 (de)compressor.

=head1 FUNCTIONS

=head2 compress

    $compressed = compress($bytes [, $level])

Compresses the given buffer and returns the resulting bytes. The input buffer
can be either a scalar or a scalar reference. The default acceleration level
(1) can be changed, with each additional level providing ~3% increase in
speed; the compression level will be negatively affected.

=head2 compress_hc

    $compressed = compress_hc($bytes [, $level])

A higher-compression, but slower, version of C<compress>. The default
compression level (9) can be changed if an optional value (0-16) is given.

=head2 decompress

=head2 uncompress

    $bytes = decompress($compressed)

Decompresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error (in case of corrupted data) undef is returned.

=head1 COMPATIBILITY

This library does not produce output that is compatible with the official
frame format. Because LZ4 did not define a container format until long after
it was released, many bindings, including this one, prepend the original data
size to the compressed data as a little-endian 4-byte integer.

If you are dealing with raw data from an external source that does not format
the data this way, you need to use the following functions:

=head2 lz4_compress

=head2 lz4_compress_hc

Same as C<compress>/C<compress_hc> but does not add the length header.

=head2 lz4_decompress

=head2 lz4_uncompress

    $bytes = decompress($compressed, $original_data_size)

Same as C<decompress>/C<uncompress> but also requires the original data size
to be given.

=head1 PERFORMANCE

This distribution contains a benchmarking script which compares several
modules available on CPAN. These are the results on a MacBook
2.6GHz Core i5 (64-bit) with Perl 5.24.1:

    Compressible data (10 KiB) - compression
    ----------------------------------------
    Compress::LZ4::compress 8   670690/s  6550 MiB/s  1.152%
    Compress::LZ4::compress     649176/s  6340 MiB/s  1.152%
    Compress::Snappy::compress  367492/s  3589 MiB/s  5.332%
    Compress::LZF::compress     127765/s  1248 MiB/s  1.865%
    Compress::LZ4::compress_hc   84620/s   826 MiB/s  1.152%
    Compress::Zlib::compress     15514/s   152 MiB/s  1.201%
    Compress::Bzip2::compress      246/s     2 MiB/s  2.070%

    Compressible data (10 KiB) - decompression
    ------------------------------------------
    Compress::LZF::decompress     1262620/s  12330 MiB/s
    Compress::LZ4::decompress      819200/s   8000 MiB/s
    Compress::Snappy::decompress   619934/s   6054 MiB/s
    Compress::Zlib::uncompress      65163/s    636 MiB/s
    Compress::Bzip2::decompress     12679/s    124 MiB/s

    Uncompressible data (10 KiB) - compression
    ------------------------------------------
    Compress::LZ4::compress 8   2102098/s  20528 MiB/s  109.231%
    Compress::LZ4::compress     1854792/s  18113 MiB/s  109.231%
    Compress::Snappy::compress  1619124/s  15812 MiB/s  104.615%
    Compress::LZF::compress     1349269/s  13176 MiB/s  101.538%
    Compress::LZ4::compress_hc    96376/s    941 MiB/s  109.231%
    Compress::Zlib::compress      66370/s    648 MiB/s  112.308%
    Compress::Bzip2::compress     54098/s    528 MiB/s  201.538%

    Uncompressible data (10 KiB) - decompression
    --------------------------------------------
    Compress::LZF::decompress     5004566/s  48873 MiB/s
    Compress::LZ4::decompress     4915199/s  48000 MiB/s
    Compress::Snappy::decompress  4906438/s  47914 MiB/s
    Compress::Zlib::uncompress     355071/s   3467 MiB/s
    Compress::Bzip2::decompress    175812/s   1717 MiB/s

=head1 SEE ALSO

L<http://lz4.org/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Compress-LZ4>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Compress::LZ4

You can also look for information at:

=over

=item * GitHub Source Repository

L<https://github.com/gray/compress-lz4>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Compress-LZ4>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Compress-LZ4>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Compress-LZ4>

=item * Search CPAN

L<http://search.cpan.org/dist/Compress-LZ4/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
