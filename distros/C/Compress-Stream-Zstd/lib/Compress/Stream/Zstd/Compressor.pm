package Compress::Stream::Zstd::Compressor;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

use Compress::Stream::Zstd ();

our @EXPORT = qw(
    ZSTD_CSTREAM_IN_SIZE
);

1;
__END__

=encoding utf-8

=head1 NAME

Compress::Stream::Zstd::Compressor - Zstd streaming compression

=head1 SYNOPSIS

    use Compress::Stream::Zstd::Compressor qw(ZSTD_CSTREAM_IN_SIZE);

    my $compressor = Compress::Stream::Zstd::Compressor->new($level);
    while (read($fh, my $buffer, ZSTD_CSTREAM_IN_SIZE)) {
        print $compressor->compress($buffer);
    }
    print $compressor->end;

=head1 DESCRIPTION

The Compress::Stream::Zstd::Compressor module provides a streaming interface to the Zstd compressor.

=head1 METHODS

=head2 Compress::Stream::Zstd::Compressor->new([$level]) :Compress::Stream::Zstd::Compressor

Create an instance of Compress::Stream::Zstd::Compressor.

=head2 $compressor->init([$level]) :Undef

(re)init the compressor.

=head2 $compressor->compress($input) :Str

Consume input stream.

=head2 $compressor->flush() :Str

Flush whatever data remains within internal buffer.

=head2 $compressor->end() :Str

Instructs to finish a frame.

=head1 CONSTANTS

=head2 ZSTD_CSTREAM_IN_SIZE

Recommended size for input buffer.

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

Zstandard by Facebook, Inc.

=cut
