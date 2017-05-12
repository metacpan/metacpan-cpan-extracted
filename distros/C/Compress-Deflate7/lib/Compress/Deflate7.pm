package Compress::Deflate7;

use 5.012000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	zlib7 deflate7
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.0';

require XSLoader;
XSLoader::load('Compress::Deflate7', $VERSION);

sub _withArgs {
  my $sub = shift;
  my $data = shift;
  my %o = @_;
  $o{Algorithm} //= 0;
  $o{FastBytes} //= 32;
  $o{Pass} //= 1;
  $o{Cycles} //= 0;

  $sub->($data, $o{Algorithm}, $o{Pass}, $o{FastBytes}, $o{Cycles});
}

sub zlib7 {
  _withArgs(\&Compress::Deflate7::_zlib7, @_);
}

sub deflate7 {
  _withArgs(\&Compress::Deflate7::_deflate7, @_);
}

1;
__END__

=head1 NAME

Compress::Deflate7 - Perl interface to 7-Zip's deflate compressor

=head1 SYNOPSIS

  use Compress::Deflate7 qw(deflate7 zlib7);
  my $rfc1951 = deflate7("...");
  my $rfc1950 = zlib7("...");

  my $level9 = zlib7(
    "...",
    Algorithm => 1,
    Pass => 10,
    FastBytes => 128,
    Cycles => 0,
  );

=head1 DESCRIPTION

This modules exposes 7-Zip's deflate compressor. The implementation
favours compression ratio over speed under high settings and is often
able to compress better than the widely used C<zlib> library.

=head2 EXPORTS

The functions C<deflate7> and C<zlib7> on request, none by default.

=head2 OPTIONS

Both functions allow several options to succeed the data parameter.
The C<Algorithm> option can be set to C<0> or C<1>, the C<Pass>
option can be set to C<1> through C<15>, C<FastBytes> can be set
to C<3> through C<258>, and C<Cycles> can be set to any positive
integer. The C<-mx=9> mode in C<7za> sets Algorithm
to 1, Pass to 10, FastBytes to 128, and Cycles to 0. The default is
0, 1, 32, 0.

=head1 SEE ALSO

L<http://www.7-zip.org/>

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2011 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as 7-Zip.

  Uses code from 7-Zip Copyright (C) 1999-2010 Igor Pavlov,
  refer to `7zip/Doc` in this distribution for details.

=cut
