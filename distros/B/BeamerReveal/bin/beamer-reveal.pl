#!/usr/bin/perl -w
# -*- cperl -*-
# PODNAME: beamer-reveal.pl
# ABSTRACT: converts the .rvl file and the corresponding pdf file to a full reveal website
#


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

sub dieExit;

my $version = 0.9;
my $author  = 'Walter Daems <walter.daems@uantwerpen.be>';

######################################
# Read command-line options/arguments
####################################

my $opt_help;
my $opt_man;
my $opt_showconfig = 0;


my $result = 
  GetOptions( "help"       => \$opt_help,
	      "man"        => \$opt_man,
	      "showconfig" => \$opt_showconfig,
	    )
  || pod2usage( -exitval => 1,
		-output  => \*STDERR );
pod2usage( -exitval => 100, -verbose => 1 ) if ($opt_help);
pod2usage( -exitval => 101, -verbose => 2 ) if ($opt_man);

my $argument = $ARGV[0] if( @ARGV == 1 );

pod2usage( -message => "Incorrect number of arguments",
	   -exitval => 1,
	   -output  => \*STDERR ) unless( $opt_showconfig
					  or
					  defined( $argument ) );

###################
# Read config file
#################
# use 1. specific location if BEAMERREVEAL_CONFIG is set,
#     2. else, home configuration folder,
#     3. or else, distribution folder
my $home = $^O eq 'MSWin32' ? $ENV{'userprofile'} : $ENV{'HOME'};
my $configDir = $ENV{'BEAMERREVEAL_CONFIG'}
  // File::Spec->catfile( $home, '.config', 'BeamerReveal' );
my $configFileName = File::Spec->catfile( $configDir, 'config.ini' );
$configFileName =
  File::Spec->catfile( File::ShareDir::dist_dir( 'BeamerReveal' ) ,
		       'config.ini' ) if ( ! -r $configFileName );
dieExit( 13, "Error: cannot find config file" )
  unless( -r $configFileName );
my $config = Config::Tiny->read( $configFileName )
  or dieExit( 14, $Config::Tiny::errstr . "\nin file '$configFileName'\n" );

########################
# generate opening line
######################
my $openingline = "beamer-reveal.pl - v$version - $author";
say STDERR $openingline . "\n" .
  ("=" x length( $openingline ) );

say STDERR "- Reading configuration file from $configFileName";

if( $opt_showconfig ) {
  say STDERR Data::Dumper->Dump( [ $config ], [ qw(Configuration) ] );
  exit(0);
}

###################
# do the hard work
#################

my ( $jobname ) = @ARGV;
my $rvlFileName = $jobname . ".rvl";
say STDERR "- Reading driver file $rvlFileName";
my $rvlFile = IO::File->new();
$rvlFile->open( "<$rvlFileName" )
  or dieExit( 20, "Error: cannot read reveal file '$rvlFileName'\n" );

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

# parse the file
my $factory = BeamerReveal->new();

## the first chunk needs to be a presentation chunk
my $presentation = $factory->createFromChunk( $chunks[0], $chunksLineNrs[0] );

my $slides = [];
my $slideRawPageCount;
eval {
  for( my $i = 1; $i < @chunks; ++$i ) {
    my $object = $factory->createFromChunk( $chunks[$i], $chunksLineNrs[$i] );
    push @$slides, $object;
  }
  
  1;
  
} or do {
  dieExit( 15, "$@" );
};

# say STDERR Data::Dumper->Dump( [ $slides], [ qw(slides) ] );

my $mediaManager =
  BeamerReveal::MediaManager->new( $jobname,
				   "${jobname}_files",
				   $config,
				   $presentation->{parameters} );

# storing the reveal framework
say STDERR "- Installing quarto/reveal.js boilerplate";
$mediaManager->revealToStore();

# generateing the content
say STDERR "- Processing the presentation";

my $slideCollection;
foreach my $slide ( @$slides ) {
  $slideCollection .= $slide->makeSlide( $mediaManager );
}

# generate all images
say STDERR "- Generating the images";
my $convertor = BeamerReveal::FrameConverter->new( "${jobname}_files",
						   "$jobname.pdf",
						   $presentation->{parameters}->{canvaswidth},
						   $presentation->{parameters}->{canvasheight} );
$convertor->toJPG();

# write the main file
say STDERR "- Producing presentation";

my $store = BeamerReveal::TemplateStore->new();
my $mainTemplate = $store->fetch( 'html', 'main.html' );

my $oFileName = "$jobname.html";
say STDERR "  - Writing $oFileName";
my $oFile = IO::File->new();
$oFile->open( ">$oFileName" )
  or dieExit( 16, "Error: cannot write to '$oFileName'" );
print $oFile
  BeamerReveal::TemplateStore::stampTemplate( $mainTemplate,
					      { TITLE => 'presentation',
						CANVASWIDTH => $presentation->{parameters}->{canvaswidth},
						CANVASHEIGHT => $presentation->{parameters}->{canvasheight},
						SLIDES => $slideCollection,
						SUBDIR => "${jobname}_files" } );
$oFile->close();

# finally let's create an index.html link
my $symlink_exists = eval { symlink("",""); 1 };
if ( $symlink_exists ) {
  say STDERR "  - Creating index.html symlink";
  symlink( "$oFileName", "index.html" );
}

########################
# generate closing line
######################
say STDERR "Done.";

#########################################################

sub dieExit {
  my ( $code, $message ) = @_;
  say STDERR $message;
  exit( $code );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

beamer-reveal.pl - converts the .rvl file and the corresponding pdf file to a full reveal website

=head1 VERSION

version 20251224.1500

=head1 SYNOPSIS

beamer-reveal.pl [--help | -h] [--man|-m] [--test|-t] <jobname>

=head1 DESCRIPTION

The B<beamer-reveal.pl> script reads a beamer-reveal (F<.rvl>) driver file
together with the F<.pdf> file (both generated by LaTeX) and converts
beamer slides to a working reveal website.

Starting by reading the documentation of the LaTeX package makes sense.
We recommend reading this documentation after that.

=head2 The F<.rvl> file

blabla

=head2 The configuration file

=head1 NAME

beamer-reveal.pl - from beamer slides to reveal presentation

=head1 OPTIONS

=over 4

=item B<--help> | B<-h>

prints help message on standard output

=item B<--man> | B<-m>

prints manual page on standard output

=back

=head1 ARGUMENT

=over 4

=item <jobname>

basename of your latex input file; this will allow C<spel-wizard.pl>
to find the F<.aux> file and the F<.spelidx> file.

=back

=head1 RETURN VALUE

=over 32

=item 0 if no errors occurred

=item 1 if a command-line syntax error occurred

=item 100 if the help message was invoked (e.g., using '-h')

=item 101 if the man page was invoked (e.g., using '-m')

=item 13 insufficient read permissions for the config file

=item 14 parsing the config file failed

=item 15 rvl syntax error

=item 16 cannot open output file

=item 20 cannot open rvl file

=item 21 unknown chunk

=item 99 installation incomplete (missing template files)

=back

=head1 BUGS

No bugs have been reported so far. If you find any, please,
send an e-mail to the author containing:

=over 32

=item - what you were trying;

=item - enough data such that I can reproduce your attempt
(F<.spelidx> file, F<.aux> file and the contents of your F<spel>
directory)

=item - what strange behavior you observed;

=item - what normal behavior you would have expected.

=back

=head1 LINKS

=over 32

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
