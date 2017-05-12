package Compress::LZW;
# ABSTRACT: Pure-Perl implementation of scaling LZW
$Compress::LZW::VERSION = '0.04';

use strictures;

use base 'Exporter';

BEGIN {
  our @EXPORT      = qw/compress decompress/;
  our @EXPORT_OK   = qw(
    $MAGIC       $MASK_BITS    $MASK_BLOCK
    $RESET_CODE  $BL_INIT_CODE $NR_INIT_CODE
    $INIT_CODE_SIZE
  );
  our %EXPORT_TAGS = (
    const => \@EXPORT_OK,
  );
}

our $MAGIC          = "\037\235";
our $MASK_BITS      = 0x1f;
our $MASK_BLOCK     = 0x80;
our $RESET_CODE     = 256;
our $BL_INIT_CODE   = 257;
our $NR_INIT_CODE   = 256;
our $INIT_CODE_SIZE = 9;

use Compress::LZW::Compressor;
use Compress::LZW::Decompressor;


sub compress {
  my ( $str ) = @_;
  
  return Compress::LZW::Compressor->new()->compress( $str );
}



sub decompress {
  my ( $str ) = @_;
  
  return Compress::LZW::Decompressor->new()->decompress( $str );
}  


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Compress::LZW - Pure-Perl implementation of scaling LZW

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Compress::LZW;
  
 my $compressed = compress($some_data);
 my $data       = decompress($compressed);

=head1 DESCRIPTION

C<Compress::LZW> is a perl implementation of the Lempel-Ziv-Welch compression
algorithm, which should no longer be patented worldwide.  It is shooting for
loose compatibility with the flavor of LZW found in the classic UNIX
compress(1), though there are a few variations out there today.  I test against
ncompress on Linux x86.

=head1 FUNCTIONS

=head2 compress

Accepts a scalar, returns compressed data in a scalar.

Wraps L<Compress::LZW::Compressor>

=head2 decompress

Accepts a (compressed) scalar, returns decompressed data in a scalar.

Wraps L<Compress::LZW::Decompressor>

=head1 EXPORTS

Default: C<compress> C<decompress>

=head1 SEE ALSO

The implementations, L<Compress::LZW::Compressor> and
L<Compress::LZW::Decompressor>.

Other Compress::* modules, especially Compress::LZV1, Compress::LZF and
Compress::Zlib.

I definitely studied some other implementations that deserve credit, in
particular: Sean O'Rourke, E<lt>SEANOE<gt> - Original author,
C<Compress::SelfExtracting>, and another by Rocco Caputo which was posted
online.

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
