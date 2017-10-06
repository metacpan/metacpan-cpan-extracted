package Compress::Zstd::Decompressor;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

use Compress::Zstd ();

our @EXPORT = qw(
    ZSTD_DSTREAM_IN_SIZE
);

1;
__END__

=encoding utf-8

=head1 NAME

Compress::Zstd::Decompressor - Zstd streaming decompression

=head1 SYNOPSIS

    use Compress::Zstd::Decompressor qw(ZSTD_DSTREAM_IN_SIZE);

    my $decompressor = Compress::Zstd::Decompressor->new;
    while (read($fh, my $buffer, ZSTD_DSTREAM_IN_SIZE)) {
        print $decompressor->decompress($buffer);
    }

=head1 DESCRIPTION

The Compress::Zstd::Decompressor module provides a streaming interface to the Zstd decompressor.

=head1 METHODS

=head2 Compress::Zstd::Decompressor->new() :Compress::Zstd::Decompressor

Create an instance of Compress::Zstd::Decompressor.

=head2 $decompressor->init() :Undef

(re)init the decompressor.

=head2 $decompressor->decompress($input) :Str

Consume input stream.

=head1 CONSTANTS

=head2 ZSTD_DSTREAM_IN_SIZE

Recommended size for input buffer.

=head1 SEE ALSO

L<Compress::Zstd>

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

Zstandard by Facebook, Inc.

=cut
