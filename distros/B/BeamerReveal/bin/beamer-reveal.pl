#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: beamer-reveal.pl
# ABSTRACT: converts the .rvl file and the corresponding pdf file to a full reveal website
our $VERSION = '20260120.1958'; # VERSION


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

use BeamerReveal::Log;

sub unixify;

######################################
# Read command-line options/arguments
####################################

my $opt_help;
my $opt_man;
my $output_dir;
my $aux_dir;
my $pdf_dir;

my $result = 
  GetOptions( "help"               => \$opt_help,
	      "man"                => \$opt_man,
	      "output-directory=s" => \$output_dir,
	      "aux-directory=s"    => \$aux_dir,
	      "pdf-directory=s"    => \$pdf_dir,
	    )
  || pod2usage( -exitval => 1,
		-output  => \*STDERR );
pod2usage( -exitval => 100, -verbose => 1 ) if ($opt_help);
pod2usage( -exitval => 101, -verbose => 2 ) if ($opt_man);

my $argument = $ARGV[0] if( @ARGV == 1 );

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
   '-|-',
  ];
my $closinglines = [ '-|-' ];

my $logger = BeamerReveal::Log->new( opening       => $openinglines,
				     closing       => $closinglines,
				     logfilename   => "$jobname.brlog",
				     labelsize     => 21,
				     activitysize  => 25 );

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

my $proc_id =
  $logger->registerTask( label    => "Slide processing",
			 progress => 0,
			 total    => 1 );
my $fc_id =
  $logger->registerTask( label    => "Frame conversion",
			 progress => 0,
			 total    => 1 );
my $mmcop_id =
  $logger->registerTask( label    => "Media copying",
			 progress => 0,
			 total    => 1 );
my $mmgen_id =
  $logger->registerTask( label    => "Animation generation",
			 progress => 0,
			 total    => 1 );
my $overall_id =
  $logger->registerTask( label    => "Overall progress",
			 progress => 0,
			 total    => 5 );

$logger->activate();


##################
# Read input file
$logger->progress( $overall_id, 0, 'reading driver file' );

# fetch the reveal file
my $rvlFileName = "$aux_dir/$jobname.rvl";
$logger->log( 0, "- Reading driver file $rvlFileName" );
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
$logger->progress( $overall_id, 1, 'parsing driver file' );

my $factory = BeamerReveal->new();

## the first chunk needs to be a presentation chunk
my $presentation = $factory->createFromChunk( $chunks[0], $chunksLineNrs[0] );

my $slides = [];
eval {
  for( my $i = 1; $i < @chunks; ++$i ) {
    my $object = $factory->createFromChunk( $chunks[$i], $chunksLineNrs[$i] );
    push @$slides, $object;
  }
  1;
} or do {
  $logger->fatal( "$@" );
};

######################
# process the content
$logger->progress( $overall_id, 2, 'processing driver file' );

my $mediaManager =
  BeamerReveal::MediaManager->new( $jobname,
				   $output_dir,
				   "${jobname}_files",
				   $presentation->{parameters} );

# storing the reveal framework
$logger->log( 0, "- Installing quarto/reveal.js boilerplate" );
$mediaManager->revealToStore();

# generateing the content
$logger->log( 0, "- Processing the presentation" );

my $slideCollection;
my $i = 0;
my $nofSlides = @$slides;
foreach my $slide ( @$slides ) {
  $logger->progress( $proc_id, $i++, "slide $i/$nofSlides", $nofSlides );
  $slideCollection .= $slide->makeSlide( $i, $mediaManager );
}
$logger->progress( $proc_id, $i );

######################
# generate all images
$logger->progress( $overall_id, 3, 'generating backgrounds' );

$logger->log( 0, "- Generating the images" );
my $convertor = BeamerReveal::FrameConverter->new( "$output_dir/${jobname}_files",
						   "$pdf_dir/$jobname.pdf",
						   $presentation->{parameters}->{canvaswidth},
						   $presentation->{parameters}->{canvasheight},
						   $fc_id );
$convertor->toJPG();

################################
# generate the copy back-orders
$logger->progress( $overall_id, 4, 'media copying' );
$mediaManager->processCopyBackOrders( $mmcop_id );

################################
# generate the generation back-orders
$logger->progress( $overall_id, 4, 'animation generation' );
$mediaManager->processConstructionBackOrders( $mmgen_id );

######################
# write the main file
$logger->progress( $overall_id, 4, 'writing presentation file' );

$logger->log( 0, "- Producing presentation" );

my $store = BeamerReveal::TemplateStore->new();
my $mainTemplate = $store->fetch( 'html', 'main.html' );

my $oFileName = "$output_dir/$jobname.html";
$logger->log( 2, "- Writing $oFileName" );
my $oFile = IO::File->new();
$oFile->open( ">$oFileName" )
  or $logger->fatal( "Error: cannot write to '$oFileName'" );
print $oFile
  BeamerReveal::TemplateStore::stampTemplate( $mainTemplate,
					      { TITLE => 'presentation',
						CANVASWIDTH => $presentation->{parameters}->{canvaswidth},
						CANVASHEIGHT => $presentation->{parameters}->{canvasheight},
						SLIDES => $slideCollection,
						SUBDIR => "${jobname}_files" } );
$oFile->close();

# finally let's create an index.html link
$logger->log( 2, "- Creating index.html link" );
link( "$oFileName", "$output_dir/index.html" );
$logger->progress( $overall_id, 5, 'done' );

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

version 20260120.1958

=head1 SYNOPSIS

beamer-reveal.pl [--help | -h] [--man|-m] <jobname>

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

=item B<--man> | B<-m>

prints manual page on standard output

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
