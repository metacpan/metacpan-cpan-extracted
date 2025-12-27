# -*- cperl -*-
# ABSTRACT: FrameConverter


package BeamerReveal::FrameConverter;
our $VERSION = '20251226.2107'; # VERSION

use strict;
use warnings;

use Carp;

use File::Which;
use File::Path;

use BeamerReveal::IPC::Run;

sub nofdigits { length( "$_[0]" ) }


sub new {
  my $class = shift;
  my ( $base, $pdffile, $xres, $yres ) = @_;

  my $self = {
	      base => $base,
	      xres => $xres,
	      yres => $yres,
	      file => $pdffile };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;
  
  $self->{pdftoppm} = File::Which::which( 'pdftoppm' )
    or die( "Error: your setup is incomplete, I cannot find pdftoppm (part of the poppler library)\n" .
	    "Install 'Poppler-utils' and make sure pdftoppm is accessible in a directory on your PATH list variable\n" );

  #  $self->{slides} = File::Spec->catfile( $self->{base}, 'media', 'Slides' );
  $self->{slides} = "$self->{base}/media/Slides";
  
  for my $item ( qw(slides) ) {
    File::Path::rmtree( $self->{$item} );
    File::Path::make_path( $self->{$item} );
  }

  return $self;
}




sub toJPG {
  my $self = shift;
  my $cmd = [ $self->{pdftoppm},
	      $self->{file},
	      "$self->{slides}/slide",
	      '-jpeg',
	      '-jpegopt',
	      'optimize=y,quality=85',
	      '-scale-to-x', @{[1.5*$self->{xres}]},
	      '-scale-to-y', @{[1.5*$self->{yres}]} ];
  BeamerReveal::IPC::Run::run( $cmd, 0, 2 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::FrameConverter - FrameConverter

=head1 VERSION

version 20251226.2107

=head1 SYNOPSIS

Worker object to convert the PDF containing the frames to bitamp files. Currently only conversion to JPEG has been implemented.

=head1 METHODS

=head2 new()

  $fc = BeamerReveal::FrameConverter->new( $base, $pdffile, $xres, $yres );

=over 4

=item . C<$base>

the directory where the files that will be used by the reveal HTML file will be stored.

=item . C<$pdffile>

the PDF file to harvest for slides

=item . C<$xres>

the x-resolution of the canvas. This will determine the resolution at which the PDF will be converted to a bitmap file.

=item . C<$yres>

the x-resolution of the canvas. This will determine the resolution at which the PDF will be converted to a bitmap file.

=item . <$fc>

the frame converter

=back

=head2 $fc->toJPG()

Converts a pdf-file to one jpg file per frame. This is done at 4/3 of the canvas resolution.

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
