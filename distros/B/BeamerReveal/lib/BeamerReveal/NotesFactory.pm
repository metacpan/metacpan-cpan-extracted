# -*- cperl -*-
# ABSTRACT: NotesFactory


package BeamerReveal::NotesFactory;
our $VERSION = '20260408.1240'; # VERSION

use strict;
use warnings;

use Carp;

use File::Which;
#use File::Path;

use Data::UUID;

use BeamerReveal::IPC::Run;
use IPC::Run qw(harness start pump finish); 

use BeamerReveal::Log;

sub nofdigits { length( "$_[0]" ) }


sub new {
  my $class = shift;
  my ( $base, $output_dir, $pdf_dir, $presentationparameters, $xres, $yres, $progressId, $debug ) = @_;

  my $self = {
	      base       => $base,
	      output_dir => $output_dir,
	      pdf_dir    => $pdf_dir,
	      presentationparameters => $presentationparameters,
	      xres       => int( $xres ), 
	      yres       => int( $yres ),
	      progressId => $progressId,
	      debug      => $debug,
	     };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  my $logger = $BeamerReveal::Log::logger;

  $self->{compiler} = File::Which::which( $self->{presentationparameters}->{compiler} )
      or $logger->fatal( "Error: your setup is incomplete, I cannot find your $self->{presentationparameters}->{compiler } compiler (should be part of your TeX installation)\n" .
			 "Make sure it is accessible in a directory on your PATH list variable\n" );
  
  
  $self->{pdftoppm} = File::Which::which( 'pdftoppm' )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find pdftoppm (part of the poppler library)\n" .
	    "Install 'Poppler-utils' and make sure pdftoppm is accessible in a directory on your PATH list variable\n" );

  $self->{slides} = "$self->{base}/media/Slides";
  
  return $self;
}




sub toJPG {
  my $self = shift;

  my $logger = $BeamerReveal::Log::logger;

  # pdf generate of n slides, and jpeg generation of n slides
  $logger->progress( $self->{progressId},
		     0, "notes generation", 2 * $self->{presentationparameters}->{nofnotes}  );
  
  #############################
  # write altered source file
  
  # 1. read the source file
  $logger->log( 2, "- Reading LaTeX source file" );
  my $sourceFileName = $self->{presentationparameters}->{sourcefilename};
  my $source = do {
      local $/ = undef;
      open my $fh, "<". $sourceFileName
	  or $logger->fatal( "Error: could not open your LaTeX source file '$sourceFileName' for reading" );
      <$fh>;
  };

  # 2. alter it
  my $notesMagic = '';
  $source =~ s/\\begin\{document\}/\\setbeamertemplate\{note page\}\{\\insertnote\}\n\\setbeameroption\{show only notes\}\n\\begin\{document\}/;


  # 3. write it to a temporary file
  $logger->log( 2, "- Writing LaTeX notes file" );
  my $id = Data::UUID->new();
  my $notesFileName;
  do {
      my $uuid = $id->create();
      $uuid = $id->to_string( $uuid );
      $notesFileName = $sourceFileName;
      $notesFileName =~ s/(\.\w)/-notes-$uuid$1/;
  } until( ! -e $notesFileName );
  my $notesFile = IO::File->new();
  $notesFile->open( ">$notesFileName" )
      or $logger->fatal( "Error could not open notes file '$notesFileName' for writing" );
  print $notesFile $source;
  $notesFile->close();

  #############
  # compile it

  # 4. run TeX
  my $cmd = [ $self->{compiler},
	      "-halt-on-error", "-interaction=nonstopmode", "-output-directory=$self->{pdf_dir}", "$notesFileName" ];
  my $logFilename = $notesFileName;
  $logFilename =~ s/\.\w+$/.log/;


  
  my $counter = 0;
  my $progress = MCE::Shared::Scalar->new( 0 );
  BeamerReveal::IPC::Run::runsmart( $cmd, 1, qr/\[(\d+)\]/,
				    sub {
				      while( scalar @_ ) {
					my $a = shift @_;
					while( $a > $counter ) {
					  ++$counter;
					  $progress->incr();
					  $logger->progress( $self->{progressId},
							     $progress->get(), "pdf generation"  );
					}
				      }
				    },
				    1, # coreId
				    2, # indent
				    undef, # directory
				    "Error: notes generation failed: check $logFilename"
      );

  ####################
  # convert it to jpg
  $notesFileName =~ s/\.\w+$/.pdf/;
  $cmd = [ $self->{pdftoppm},
	   $notesFileName,
	   "$self->{output_dir}/$self->{slides}/notes",
	   '-jpeg',
	   '-jpegopt',
	   'optimize=y,quality=85',
	   '-scale-to-x', @{[1.5*$self->{xres}]},
	   '-scale-to-y', @{[1.5*$self->{yres}]},
	   '-progress',
	 ];
  my $maxNote = 0;
  BeamerReveal::IPC::Run::runsmart( $cmd, 2, qr/^(\d+) (\d+) .*$/,
				    sub {
				      while( scalar @_ ) {
					my ( $a, $b ) = ( shift @_, shift @_ );
					$logger->progress( $self->{progressId},
							   $a, "note $1/$2", $b );
					$maxNote = $b;
				      }
				    },
				    0, # coreId
				    2, # indent
				    undef, # directory
				    "Error: notes conversion failed, is your notes PDF damaged?"
      );

  $notesFileName =~ s/\.\w+$//;
  foreach my $file ( glob( "$notesFileName*" ) ) {
    unlink $file unless( defined $self->{debug} );
  }

  my @list = ( 0 ); # create a dummy element to allow for one-indexed addressing
  
  for (my $i = 1; $i <= $maxNote; ++$i ) {
    push @list, sprintf( "$self->{slides}/notes-%0" . nofdigits( $maxNote ) . 'd.jpg',
			 $i );
  }
  return \@list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::NotesFactory - NotesFactory

=head1 VERSION

version 20260408.1240

=head1 SYNOPSIS

Worker object to distill notes from the original Beamer TeX file.

=head1 METHODS

=head2 new()

  $nf = BeamerReveal::NotesFactory->new( $base, $presentationparameters $xres, $yres, $progressId, $debug );

=over 4

=item . C<$base>

the directory where the files that will be used by the reveal HTML file will be stored.

=item . C<$presentationparameters>

the presentation data that we need to determine the compiler used

=item . C<$xres>

the x-resolution of the canvas. This will determine the resolution at which the PDF will be converted to a bitmap file.

=item . C<$yres>

the x-resolution of the canvas. This will determine the resolution at which the PDF will be converted to a bitmap file.

=item . C<$progressId>

the ID of the progress bar that displays the progress on screen.

=item . C<$debug>

runs the factory in debug mode (undef = off, defined = on),  i.e. no intermediate files are cleaned.
=item . <$nf>

the notes factory

=back

=head2 $fc->toJPG()

Converts the presentation to one jpg file per frame. This is done at 3/4 of the canvas resolution.
The process goes in several steps

=over 4

=item . writing an altered source file

=item . compiling it

=item . converting it to jpg

=back

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
