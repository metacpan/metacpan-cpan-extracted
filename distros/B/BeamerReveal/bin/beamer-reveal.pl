#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: beamer-reveal.pl
# ABSTRACT: converts the .rvl file and the corresponding pdf file to a full reveal website
our $VERSION = '20260408.1240'; # VERSION


use strict;

use Getopt::Long;
use Pod::Usage;

use Config::Tiny;

use File::Spec;
use File::ShareDir;
use File::Copy::Recursive;

use Data::Dumper;

use BeamerReveal;
use BeamerReveal::TemplateStore;
use BeamerReveal::FrameConverter;
use BeamerReveal::NotesFactory;
use BeamerReveal::Log;

sub unixify;

######################################
# Read command-line options/arguments
####################################

my $opt_help;
my $opt_version;
my $opt_man;
my $opt_debug;
my $output_dir;
my $aux_dir;
my $pdf_dir;

my $result = 
  GetOptions( "help"               => \$opt_help,
	      "version"            => \$opt_version,
	      "man"                => \$opt_man,
	      "debug"              => \$opt_debug,
	      "output-directory=s" => \$output_dir,
	      "aux-directory=s"    => \$aux_dir,
	      "pdf-directory=s"    => \$pdf_dir,
	    )
  || pod2usage( -exitval => 1,
		-output  => \*STDERR );
pod2usage( -exitval => 100, -verbose => 1 ) if ($opt_help);
pod2usage( -exitval => 101, -verbose => 2 ) if ($opt_man);

my $argument = $ARGV[0] if( @ARGV == 1 );

if ( $opt_version ) {
  say STDOUT "v${BeamerReveal::VERSION}";
  exit(0);
}

pod2usage( -message => "Incorrect number of arguments",
	   -exitval => 1,
	   -output  => \*STDERR ) unless( defined( $argument ) );

###################
# do the hard work
#################

# fetch the jobname and get rid of these nasty windows backslashes...
my ( $jobname ) = @ARGV;
$jobname =~ s/\\/\//g;

my $openinglines =
  [
   '-|-',
   "--  beamer-reveal.pl|v${BeamerReveal::VERSION} --",
   '--  (C) 2025-2026 Walter PM Daems <wdaems@cpan.org>|GPLv3 --',
   '--  This script uses materials from:|--',
   '--    - reveal.js (C) Hakim El Hattab and contributors|MIT license --',
   '--    - Quarto    (C) Posit Software, PBC and contributors|MIT license --',
   '-|-',
  ];
my $closinglines = [ '-|-' ];

my $logger = BeamerReveal::Log->new( opening       => $openinglines,
				     closing       => $closinglines,
				     logfilename   => "$jobname.brlog",
				     labelsize     => 21,
				     activitysize  => 28 );

###############################
# set defaults for directories
$pdf_dir ||= '.';
$aux_dir ||= $pdf_dir;
$output_dir ||= '.';

# unixify these directories
foreach my $path ( \$pdf_dir, \$aux_dir, \$output_dir ) {
  $$path = unixify( $$path );
}


$logger->log( 0, "- Using the following directories:" );
$logger->log( 2, "aux-files    : '$aux_dir'" );
$logger->log( 2, "pdf-files    : '$pdf_dir'" );
$logger->log( 2, "output-files : '$output_dir'" );

my $fc_id =
  $logger->registerTask( label    => "Frame conversion",
			 progress => 0,
			 total    => 1 );
my $ng_id =
  $logger->registerTask( label    => "Note generation",
			 progress => 0,
			 total    => 1 );
my $mmanimgen_id =
  $logger->registerTask( label    => "Animation generation",
			 progress => 0,
			 total    => 1 );
my $mmstillgen_id =
  $logger->registerTask( label    => "Still generation",
			 progress => 0,
			 total    => 1 );
my $mmvovergen_id =
  $logger->registerTask( label    => "Voice-over generation",
			 progress => 0,
			 total    => 1 );
my $proc_id =
  $logger->registerTask( label    => "Slide processing",
			 progress => 0,
			 total    => 1 );
my $mmcop_id =
  $logger->registerTask( label    => "Media copying",
			 progress => 0,
			 total    => 1 );
my $overall_id =
  $logger->registerTask( label    => "Overall progress",
			 progress => 0,
			 total    => 9 );

$logger->activate();

##################
# Read input file

# fetch the reveal file
my $rvlFileName = "$aux_dir/$jobname.rvl";
$logger->log( 0, "- Reading driver file $rvlFileName" );
$logger->progress( $overall_id, 0, 'reading driver file' );

my $rvlFile = IO::File->new();
$rvlFile->open( "<$rvlFileName" )
  or $logger->fatal( "Error: cannot read reveal file '$rvlFileName'\n" );

# skip first comment lines
my $lineCtr = 0;
my $line = '%%';
while ( $line =~ /^%%/ ) {
  ++$lineCtr;
  $line = <$rvlFile>;
}

# slurp the entire file while keepign track of the linenumbers
my $content = $line . do { local $/; <$rvlFile> };
my @chunks = split( '@@', $content );
shift @chunks;
my @chunksLineNrs;
$chunksLineNrs[0] = $lineCtr;
for( my $i = 0; $i < @chunks; ++$i ) {
  $lineCtr += $chunks[$i] =~ tr/\n//;
  $chunksLineNrs[$i+1] = $lineCtr;
}

#################
# parse the file

$logger->log( 0, "- Parsing driver file $rvlFileName" );
$logger->progress( $overall_id, 0.25, 'parsing driver file' );

my $factory = BeamerReveal->new();

## the first chunk needs to be a presentation chunk
my $presentation = $factory->createFromChunk( $chunks[0], $chunksLineNrs[0] );

my $mediaManager =
  BeamerReveal::MediaManager->new( $jobname,
				   $output_dir,
				   "${jobname}_files",
				   $presentation->{parameters},
				   $opt_debug );

## parse all slides
my $slides = [];
my $nofNotes = 0;
eval {
  for( my $i = 1; $i < @chunks; ++$i ) {
    my $object = $factory->createFromChunk( $chunks[$i], $chunksLineNrs[$i] );
    $object->{hasnotes} = ++$nofNotes if( $object->{hasnotes} ); #if notes, add sequence number
    my $contentToGenerate = $object->extractContentToGenerate( $i, $mediaManager, $presentation );
    push @$slides, {
		    slide => $object,
		    contentToGenerate => $contentToGenerate
		   };
  }
  1;
} or do {
  $logger->fatal( "$@" );
};
$presentation->{parameters}->{nofnotes} = $nofNotes;

$logger->progress( $overall_id, 0.5, 'installing boiler plate' );

# storing the reveal framework
$logger->log( 0, "- Installing quarto/reveal.js boilerplate" );
$mediaManager->revealToStore();

######################
# generate all images
$logger->progress( $overall_id, 1, 'generating backgrounds' );

$logger->log( 0, "- Generating the images" );
my $frameConvertor = BeamerReveal::FrameConverter->new( "${jobname}_files",
							$output_dir,
							"$pdf_dir/$jobname.pdf",
							$presentation->{parameters}->{canvaswidth},
							$presentation->{parameters}->{canvasheight},
							$fc_id,
							$opt_debug );
my $list = $frameConvertor->toJPG();
$mediaManager->backgroundsToStore( $list );

##########################
# geneate the notes pages
$logger->progress( $overall_id, 2, 'generating notes pages' );

$logger->log( 0, "- Generating the notes pages" );
if ( $nofNotes ) {
  my $notesFactory = BeamerReveal::NotesFactory->new( "${jobname}_files",
						      $output_dir,
						      $pdf_dir,
						      $presentation->{parameters},
						      $presentation->{parameters}->{canvaswidth} / 2,
						      $presentation->{parameters}->{canvasheight} / 2,
						      $ng_id,
						      $opt_debug);
  my $list = $notesFactory->toJPG();
  $mediaManager->notesToStore( $list );
}
else {
  $logger->progress( $ng_id, 1, 'no notes found', 1 );
}

# here's the plan/issue
# - creating slidecollection late because we need images and notes to be present for embedding
# - problem: at that moment, the animation generation and media-copying has not been done yet.
# - yet, these need to be present also for embedding before we can create the slide collection.
# Question: can we postpone making the slidecollection until after copying media and generating animations/stills?
# - problem: MM->mediaFromStore() composes the basic info that is needed for the generation. It is only called
# - when processing the slidecollection.
# Possible solution: work in two passes
# Can we only treat animations/stills and the detection of notes in the first pass?
# Make a method next to makeSlide() that is extractContentToGenerate(), that only treats animations and stills
# and prepares the backorders with the required info.
# then we can generate the backorders
# processs the backorders
# and go to makeslide.
# The only issue is that the filenaming using the hamac_sha256_hex may not be unique if the same expand-once
# command is used in multiple stills and animations... the filename will not be unique
# the naming needs to be based on the full stamped tex-file instead of on the argument of the \animation command only.
# remaining issue:
# _fromStore does a correct job for embedding, but not for the non-embedding, because this
# tires to coume up with a new filename...

################################
# generate the generation back-orders

$logger->progress( $overall_id, 3, 'animation generation' );
$logger->log( 0, "- Generating animations" );
$mediaManager->processAnimationBackOrders( $mmanimgen_id );

$logger->progress( $overall_id, 4, 'still generation' );
$logger->log( 0, "- Generating stills" );
$logger->log( 0, "- Generating all new media" );
$mediaManager->processStillBackOrders( $mmstillgen_id );

$logger->progress( $overall_id, 5, 'voice-over generation' );
$logger->log( 0, "- Generating voice-overs" );
$logger->log( 0, "- Generating all new media" );
$mediaManager->processVoiceoverBackOrders( $mmvovergen_id );

######################
# process the content
# generating the content
$logger->log( 0, "- Processing the presentation" );
$logger->progress( $overall_id, 6, 'processing presentation' );

my $slideCollection;
my $i = 0;
my $nofSlides = @$slides;
foreach my $object ( @$slides ) {
  $logger->progress( $proc_id, $i++, "slide $i/$nofSlides", $nofSlides );
  $slideCollection .= $object->{slide}->makeSlide( $i, $mediaManager, $presentation,
						   $object->{contentToGenerate} );
}
$logger->progress( $proc_id, $i );


################################
# generate the copy back-orders
$logger->progress( $overall_id, 7, 'media copying' );

$logger->log( 0, "- Collecting all existing media" );
$mediaManager->processCopyBackOrders( $mmcop_id );


######################
# write the main file
$logger->progress( $overall_id, 8, 'writing presentation file' );

$logger->log( 0, "- Producing presentation" );

my $store = BeamerReveal::TemplateStore->new();
my $mainTemplate = $store->fetch( 'html', 'main.html' );

my $oFileName = "$output_dir/$jobname.html";
$logger->log( 2, "- Writing $oFileName" );
my $oFile = IO::File->new();

$presentation->{parameters}->{autoslide} ||= 'false';
$oFile->open( ">$oFileName" )
  or $logger->fatal( "Error: cannot write to '$oFileName'" );
print $oFile
  BeamerReveal::TemplateStore::stampTemplate( $mainTemplate,
					      { PRODUCER  => "beamer-reveal.sty $presentation->{parameters}->{latexversion} / beamer-reveal.pl v${BeamerReveal::VERSION}",
						TITLE     => $presentation->{parameters}->{title},
						AUTHOR    => $presentation->{parameters}->{author},
						AUTOSLIDE => $presentation->{parameters}->{autoslide},
						LOOP      => $presentation->{parameters}->{loop},
						CANVASWIDTH  => $presentation->{parameters}->{canvaswidth},
						CANVASHEIGHT => $presentation->{parameters}->{canvasheight},
						SLIDES    => $slideCollection,
						SUBDIR    => "${jobname}_files" } );
$oFile->close();

# finally let's create an index.html link
$logger->log( 2, "- Creating index.html link" );
link( "$oFileName", "$output_dir/index.html" );
$logger->progress( $overall_id, 9, 'done' );

########################
# generate closing line
######################
$logger->finalize();

sub unixify {
  $_[0] =~ s/\\/\//g;
  $_[0] =~ s/\/$//;
  return $_[0];
}

#########################################################

__END__

=pod

=encoding UTF-8

=head1 NAME

beamer-reveal.pl - converts the .rvl file and the corresponding pdf file to a full reveal website

=head1 VERSION

version 20260408.1240

=head1 SYNOPSIS

beamer-reveal.pl [options] <jobname>

=head1 DESCRIPTION

The B<beamer-reveal.pl> script reads a beamer-reveal (F<.rvl>) driver file
together with the F<.pdf> file (both generated by LaTeX) and converts
beamer slides to a working reveal website.

Starting by reading the documentation of the LaTeX package makes sense.
We recommend reading this documentation after that.

=head2 The F<.rvl> file

The syntax will be documented as soon as it reaches stability.

=head2 The configuration file

There is not configuration file.

=head1 NAME

beamer-reveal.pl - from beamer slides to reveal presentation

=head1 OPTIONS

=over 4

=item B<--help> | B<-h>

prints help message on standard output

=item B<--version> | B<-v>

prints version number on standard output

=item B<--man> | B<-m>

prints manual page on standard output

=item B<--debug> | B<-d>

runs tool in debug mode (i.e. no file cleaning in \jobname_files/media and for the notes in your working directory)

=item B<--output-directory> | B<-o>

target directory where the reveal html files will end up in. Defaults to '.'.

=item B<--aux-directory> | B<-a>

directory where the rvl file (and other auxiliary files) will be read from.
Defaults to the pdf-directory.

=item B<--pdf-directory> | B<-p>

directory where the PDF file of your beamer-presentation is stored. Defaults to '.'.

=back

=head1 ARGUMENT

=over 4

=item <jobname>

basename of your latex input file; this will allow C<spel-wizard.pl>
to find the F<.aux> file and the F<.spelidx> file.

=back

=head1 RETURN VALUE

The return value is not meaningful. The project is not mature enough and its use
mode is unsufficiently known to implement the appropriate return value strategy.

=head1 BUGS

No bugs have been reported so far. If you find any, please,
send an e-mail to the author containing:

=over 4

=item - what you were trying;

=item - enough data such that I can reproduce your attempt
(F<.tex> file, F<.rvl> file, F<.brlog> file and the F<jobname_files>
 directory created by the script;

=item - what strange behavior you observed;

=item - what normal behavior you would have expected.

=back

=head1 LINKS

=over 4

=item https://metacpan.org/pod/beamer-reveal

=item https://ctan.org/pkg/beamer-reveal

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
