package Compress::Stream::Zstd;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.205";

our @EXPORT = qw(
    compress
    decompress
    uncompress
    ZSTD_VERSION_NUMBER
    ZSTD_VERSION_STRING
    ZSTD_MAX_CLEVEL
    ZSTD_MIN_CLEVEL
);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Compress::Stream::Zstd - Perl interface to the Zstd (Zstandard) (de)compressor

=head1 NOTE

This module is a fork of L<Compress-Zstd|https://github.com/spiritloose/Compress-Zstd>.
It contains a few changes to make streaming compression/uncompression more robust.
The only reason for this fork is to allow the module to work with `IO-Compress-Zstd`.
The hope is that the changes made here can be merged back upstream and this module can be retired.

=head1 SYNOPSIS

    use Compress::Stream::Zstd;

    my $compressed = compress($bytes);
    my $decompressed = decompress($compressed);

=head1 DESCRIPTION

The Compress::Stream::Zstd module provides an interface to the Zstd (de)compressor.

=head1 FUNCTIONS

=head2 compress($source [, $level])

Compresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error undef is returned.

=head2 decompress($source)

=head2 uncompress($source)

Decompresses the given buffer and returns the resulting bytes. The input
buffer can be either a scalar or a scalar reference.

On error (in case of corrupted data) undef is returned.

=head1 CONSTANTS

=head2 ZSTD_VERSION_NUMBER

=head2 ZSTD_VERSION_STRING

=head2 ZSTD_MAX_CLEVEL

=head2 ZSTD_MIN_CLEVEL

=head1 SEE ALSO

L<http://www.zstd.net/>

=head1 LICENSE

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

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

Some streaming enhancement by Paul Marquess  E<lt>pmqs@cpan.orgE<gt>

Zstandard by Facebook, Inc.

=cut
