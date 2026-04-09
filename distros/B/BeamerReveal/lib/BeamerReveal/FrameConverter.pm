# -*- cperl -*-
# ABSTRACT: FrameConverter


package BeamerReveal::FrameConverter;
our $VERSION = '20260408.1240'; # VERSION

use strict;
use warnings;

use Carp;

use File::Which;
use File::Path;

use BeamerReveal::IPC::Run;
use IPC::Run qw(harness start pump finish); 

use BeamerReveal::Log;

sub nofdigits { length( "$_[0]" ) }


sub new {
  my $class = shift;
  my ( $base, $outputdir, $pdffile, $xres, $yres, $progressId ) = @_;

  my $self = {
	      base       => $base,
	      outputdir  => $outputdir,
	      xres       => $xres,
	      yres       => $yres,
	      file       => $pdffile,
	      progressId => $progressId,
	     };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  my $logger = $BeamerReveal::Log::logger;
  
  $self->{pdftoppm} = File::Which::which( 'pdftoppm' )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find pdftoppm (part of the poppler library)\n" .
	    "Install 'Poppler-utils' and make sure pdftoppm is accessible in a directory on your PATH list variable\n" );

  $logger->fatal( "Error: cannot find $pdffile, run your latex compiler first to produce the PDF file." ) unless ( -r $pdffile );
  
  $self->{slides} = "$self->{base}/media/Slides";
  
  for my $item ( qw(slides) ) {
    File::Path::rmtree( "$outputdir/$self->{$item}" );
    File::Path::make_path( "$outputdir/$self->{$item}" );
  }

  return $self;
}




sub toJPG {
  my $self = shift;
  
  my $cmd = [ $self->{pdftoppm},
	      $self->{file},
	      "$self->{outputdir}/$self->{slides}/slide",
	      '-jpeg',
	      '-jpegopt',
	      'optimize=y,quality=85',
	      '-scale-to-x', @{[1.5*$self->{xres}]},
	      '-scale-to-y', @{[1.5*$self->{yres}]},
	      '-progress',
	    ];
  my $logger = $BeamerReveal::Log::logger;
  my $maxSlide = 0;
  BeamerReveal::IPC::Run::runsmart( $cmd, 2, qr/^(\d+) (\d+) .*$/,
				    sub {
				      while( scalar @_ ) {
					my ( $a, $b ) = ( shift @_, shift @_ );
					$logger->progress( $self->{progressId},
							   $a, "background $1/$2", $b );
					$maxSlide = $b;
				      }
				    },
				    0, # coreId
				    2, # indent
				    undef, # directory
				    "Error: frame conversion failed, is your beamer PDF damaged?"
				  );

  my @list = ( 0 ); # create a dummy element to allow for one-indexed addressing
   
  for (my $i = 1; $i <= $maxSlide; ++$i ) {
    push @list, sprintf( "$self->{slides}/slide-%0" . nofdigits( $maxSlide ) . 'd.jpg',
			 $i );
  }
  return \@list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::FrameConverter - FrameConverter

=head1 VERSION

version 20260408.1240

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

Converts a pdf-file to one jpg file per frame. This is done at 3/2 of the canvas resolution.

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
