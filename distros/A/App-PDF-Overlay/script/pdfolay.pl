#!/usr/bin/perl -w

# Over/underlay PDF documents.

# Author          : Johan Vromans
# Created On      : Tue Apr 19 08:17:03 2022
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr 19 16:47:08 2022
# Update Count    : 52
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use App::PDF::Overlay;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = ( 'pdfolay', $App::PDF::Overlay::VERSION );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $overlay;			# the overlay file
my $back;			# insert behind
my $restart;			# restart overlay at a new source file
my $repeat;			# repeat overlay pages
my $output;			# the new output document
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

unless ( @ARGV ) {
    die("Missing input document\n");
}

unless ( $output ) {
    $output = "__new__.pdf";
    warn("No output specified, using \"$output\"\n");
}
elsif ( $verbose ) {
    warn("Creating document: $output\n");
}

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use PDF::API2 2.042;

my $o_pdf;
if ( $overlay ) {
    $o_pdf = PDF::API2->open($overlay)
      or die("$overlay: $!\n");
}
my $o_pix = 1;			# page index

my $pdf = PDF::API2->new;

process($_) for @ARGV;

$pdf->saveas($output);
warn("Wrote: $output\n") if $verbose;

exit 0;

################ Subroutines ################

sub process {
    my ( $file ) = @_;

    my $i_pdf = PDF::API2->open($file);
    my $pages = $i_pdf->page_count;
    warn( "Processing: \"$file\", $pages page",
	  $pages == 1 ? "" : "s", "\n" ) if $verbose;

    $o_pix = 1 if $restart;

    unless ( $pdf->page_count ) {
	# Copy document properties from the first document.
	for my $m ( qw( title is_encrypted version author subject
			keywords creator producer created modified
			xml_metadata
			page_layout page_mode ) ) {
	    ####TODO
	    next if $m eq "page_mode"; # see PDF::API2 issue 49
	    next unless $_ = $i_pdf->$m;
	    $pdf->$m($_);
	}
	for my $m ( qw( info_metadata ) ) {
	    my %i = $pdf->$m;
	    next unless %i;
	    while ( my ( $k, $v) = each %i ) {
		$pdf->$m( $k, $v );
	    }
	}
	for my $m ( qw( viewer_preferences default_page_boundaries ) ) {
	    my %i = $pdf->$m;
	    next unless %i;
	    delete $i{non_full_screen_page_mode};
	    $pdf->$m(%i);
	}
    }

    for ( my $p = 1; $p <= $pages; $p++ ) {
	my $page = $pdf->page;

	$pdf->import_page( $i_pdf, $p, $page ) unless $back;

	if ( $overlay && $o_pix ) {
	    $page = $pdf->import_page( $o_pdf, $o_pix, $page );
	    $o_pix++;
	    if ( $o_pix > $o_pdf->page_count ) {
		$o_pix = $repeat ? 1 : 0;
	    }
	}

	$pdf->import_page( $i_pdf, $p, $page ) if $back;
    }

}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $version = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        require Pod::Find;
        Pod::Usage->import;
	my $f = Pod::Find::pod_where( { -inc => 1}, "App::PDF::Overlay" );
        &pod2usage( -input => $f );
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions( 'overlay=s' => \$overlay,
		    'back|behind' => \$back,
		    'output=s'	=> \$output,
		    'restart'	=> \$restart,
		    'repeat'	=> \$repeat,
		    'ident'	=> \$ident,
		    'version'	=> \$version,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'help|?'	=> \$help,
		    'man'	=> \$man,
		    'debug'	=> \$debug )
	  or $pod2usage->(2);
    }
    if ( $version ) {
	print ("This is $my_package [$my_name $my_version]\n");
	exit;
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}
