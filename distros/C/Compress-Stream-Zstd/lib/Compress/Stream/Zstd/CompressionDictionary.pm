package Compress::Stream::Zstd::CompressionDictionary;
use 5.008001;
use strict;
use warnings;

use Compress::Stream::Zstd ();

sub new_from_file {
    my ($class, $file, $level) = @_;
    open my $fh, '<', $file or die $!;
    local $/;
    my $dict = <$fh>;
    close $fh;
    $class->new($dict, $level || 1);
}

1;
__END__

=encoding utf-8

=head1 NAME

Compress::Stream::Zstd::CompressionDictionary - Zstd compression dictionary

=head1 SYNOPSIS

    use Compress::Stream::Zstd::CompressionContext;
    use Compress::Stream::Zstd::CompressionDictionary;

    my $cdict = Compress::Stream::Zstd::CompressionDictionary->new_from_file($filename, $level);
    my $cctx = Compress::Stream::Zstd::CompressionContext->new;
    my $dest = $cctx->compress_using_dict($src, $cdict);

=head1 DESCRIPTION

(Experimental) The Compress::Stream::Zstd::CompressionDictionary module provides Zstd compression dictionaries.

=head1 METHODS

=head2 Compress::Stream::Zstd::CompressionDictionary->new($dict) :Compress::Stream::Zstd::CompressionDictionary

Create an instance of Compress::Stream::Zstd::CompressionDictionary.

=head2 Compress::Stream::Zstd::CompressionDictionary->new_from_file($filename) :Compress::Stream::Zstd::CompressionDictionary

Create an instance of Compress::Stream::Zstd::CompressionDictionary from file.

=head1 SEE ALSO

L<Compress::Stream::Zstd>

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
