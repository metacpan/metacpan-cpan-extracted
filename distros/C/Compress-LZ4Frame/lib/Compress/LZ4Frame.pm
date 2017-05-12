package Compress::LZ4Frame;
# ABSTRACT: Compression package using the lz4frame library
$Compress::LZ4Frame::VERSION = '0.012';
use 5.010_001;
use strict;
use warnings;
use vars qw($VERSION);

use base qw(XSLoader);
use Exporter qw(import);

__PACKAGE__->load($VERSION);

our @EXPORT_OK = qw(compress compress_checksum decompress looks_like_lz4frame);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Compress::LZ4Frame - Compression package using the lz4frame library

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use Compress::LZ4Frame qw(:all);

    my @data = map { rand } (1..50000);
    my $packed = pack('d*', @data);

    # compress
    my $compressed = compress($packed);
    # or with checksum
    my $compressed = compress_checksum($packed);

    # check data
    looks_like_lz4frame($compressed);   # some true value
    looks_like_lz4frame($packed);       # some false value

    # decompress
    my $decompressed = decompress($compressed);

    my @result = unpack('d*', $decompressed);
    # @result now contains the same values as @data did

=head1 FUNCTIONS

=head2 compress

    $compressed = compress($data [, $level])

Uses the lz4frame library to compress the given data. The optional compression level is passed through to lz4frame.

=head2 compress_checksum

Usage is the same as compress. The only difference is, that a checksum is included into the resulting data,
which will be checked by decompress.

=head2 decompress

    $data = decompress($compressed)

Decompresses the given data.

=head2 looks_like_lz4frame

    $okay = looks_like_lz4frame($data)

Checks the given data for a valid LZ4 frame.

=head1 COMPATIBILITY

The format of the compressed data is incompatible to that of L<Compress::LZ4>, thus they are not interoperable.
Other than that this package should be compatible to every program/library working with the official lz4frame format.

=head1 ACKNOWLEDGEMENTS

Many thanks goes to the following individuals who helped improve C<Compress-LZ4Frame>:

I<Yann Collet> for creating the LZ4 library and the lz4frame format, also for helping me fix nasty bugs.

I<A. Sinan Ünür> for nmake support.

=head1 SEE ALSO

=over 4

=item *

L<LZ4 on Github|https://github.com/Cyan4973/lz4>

=item *

L<Interoperable LZ4 implementations|http://cyan4973.github.io/lz4/#interoperable-lz4>

=back

=head1 AUTHOR

Felix Bytow <felix.bytow@autinity.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by afr-consulting GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
