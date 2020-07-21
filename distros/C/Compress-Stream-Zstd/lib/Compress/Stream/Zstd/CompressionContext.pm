package Compress::Stream::Zstd::CompressionContext;
use 5.008001;
use strict;
use warnings;

use Compress::Stream::Zstd ();

1;
__END__

=encoding utf-8

=head1 NAME

Compress::Stream::Zstd::CompressionContext - Zstd compression context

=head1 SYNOPSIS

    use Compress::Stream::Zstd::CompressionContext;

    my $cctx = Compress::Stream::Zstd::CompressionContext->new;
    my $dest = $cctx->compress($src, $level);

=head1 DESCRIPTION

(Experimental) The Compress::Stream::Zstd::CompressionContext module provides Zstd compression context.

=head1 METHODS

=head2 Compress::Stream::Zstd::CompressionContext->new() :Compress::Stream::Zstd::CompressionContext

Create an instance of Compress::Stream::Zstd::CompressionContext.

=head2 $cctx->compress($source [, $level])

Compresses the given buffer and returns the resulting bytes.

On error undef is returned.

=head2 $cctx->compress_using_dict($source, $dict)

Compresses the given buffer using compression dictionary and returns the resulting bytes.

On error undef is returned.

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
