#!/usr/bin/perl

# ireal2cvt -- convert iRealPro song data

# Author          : Johan Vromans
# Created On      : Fri Jan 15 19:15:00 2016
# Last Modified By: Johan Vromans
# Last Modified On: Mon Nov  5 21:34:36 2018
# Update Count    : 130
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../CPAN";
use lib "$FindBin::Bin/../lib";
use App::Packager qw( :name Data::iRealPro );

use Data::iRealPro 1.11;
use Data::iRealPro::Output;

################ Setup  ################

# Process command line options, config files, and such.
my $options;
$options = app_setup("ireal2pdf", $Data::iRealPro::VERSION);

################ Presets ################

$options->{trace} = 1   if $options->{debug};
$options->{verbose} = 1 if $options->{trace};

################ Activate ################

main($options);

################ The Process ################

use File::Glob qw(:bsd_glob);

sub main {
    my ($options) = @_;
    binmode(STDERR,':utf8');
    @ARGV = map { glob } @ARGV if $^O eq 'MSWin32';
    Data::iRealPro::Output->new($options)->processfiles(@ARGV);
}

################ Options and Configuration ################

use Getopt::Long 2.13;
use File::Spec;
use Carp;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);
my %configs;

sub app_setup {
    my ($appname, $appversion, %args) = @_;
    my $version = 0;		# handled locally
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
	($my_name, $my_version) = ($appname, $appversion);
    }
    else {
	($my_name, $my_version) = qw( MyProg 0.01 );
    }

    %configs =
      ( sysconfig  => File::Spec->catfile ("/", "etc", lc($my_name) . ".conf"),
	userconfig => File::Spec->catfile($ENV{HOME}, ".".lc($my_name), "conf"),
	config     => "." . lc($my_name) .".conf",
#	config     => lc($my_name) .".conf",
      );

    my $options =
      {
       verbose		=> 0,		# verbose processing

       ### ADD OPTIONS HERE ###

       output		=> undef,
       transpose	=> 0,
       toc		=> undef,
       neatify		=> 0,

       # XML frontend.
       catalog		=> "$FindBin::Bin/../res/catalog.xml",
       'suppress-upbeat' => 1,
       'suppress-text'  => 0,
       'override-alt'	=> 1,
       condense		=> 1,
       musescore	=> undef,

       # Development options (not shown with -help).
       debug		=> 0,		# debugging
       trace		=> 0,		# trace (show process)

       # Service.
       _package		=> $my_package,
       _name		=> $my_name,
       _version		=> $my_version,
       _stdin		=> \*STDIN,
       _stdout		=> \*STDOUT,
       _stderr		=> \*STDERR,
       _argv		=> [ @ARGV ],
      };

    # Colled command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
	 ($clo,

	  ### ADD OPTIONS HERE ###

	  'output|o=s',
	  'generate=s',
	  'select=i',
	  'list',
	  'split',
	  'dir=s',
	  'playlist=s',
	  'npp=s',
	  'transpose|x=i',
	  'toc!',
	  'catalog=s',
	  'neatify=i',
	  'musescore!',
	  'condense!',
	  'suppress-upbeat!',
	  'suppress-text!',
	  'override-alt',

	  # # Configuration handling.
	  # 'config=s',
	  # 'noconfig',
	  # 'sysconfig=s',
	  # 'nosysconfig',
	  # 'userconfig=s',
	  # 'nouserconfig',
	  # 'define|D=s%' => sub { $clo->{$_[1]} = $_[2] },

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|h|?'		=> \$help,
	  'man'			=> \$man,
	  'version'		=> \$version,
	  'verbose',
	  'trace',
	  'debug',
	 ) )
    {
	# GNU convention: message to STDERR upon failure.
	$pod2usage->(2);
    }
    # GNU convention: message to STDOUT upon request.
    app_ident(\*STDOUT), exit if $version;
    $pod2usage->(1) if $help;
    $pod2usage->( VERBOSE => 2 ) if $man;
    app_ident(\*STDOUT) if $ident;

    $pod2usage->(2) unless @ARGV;

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;

    $options;
}

sub app_ident {
    my ($fh) = @_;
    print {$fh} ("This is ",
		 $my_package
		 ? "$my_package [$my_name $my_version]"
		 : "$my_name version $my_version",
		 "\n");
}

1;

__END__

################ Documentation ################

=head1 NAME

irealcvt - parse and convert iRealPro data

=head1 SYNOPSIS

irealcvt [options] file [...]

 Options:

    --output=XXX	Desired output file name.
			File name extension controls the output type.
    --select=NN		Select a single song from a playlist.
    --list		Prints the titles of the songs from a playlist.
    --transpose=[+-]NN  -x  Transpose up/down semitones.

  iRealPro (HTML) output options:

    --split		Splits the songs from a playlist into individual
			HTML files. Use --dir to control where the
			files will be written.
    --dir=XXX		Specifies the result directory for --split.

  Imager (PDF/PNG) output options:

    --npp=[hand|hand_strict|standard]	Near pixel-perfect output.
    --[no]toc		Produces [suppresses] the table of contents.

  MusicXML input options:

    --[no-]suppress-upbeat  Suppress an initial upbeat (default).
    --[no-]suppress-text    Suppress all texts.
    --[no-]override-alt     Change series of alt modifications to a single
			    'alt' quality (default).
    --[no-]condense	    Condense chords that may not have enough
			    space to be shown (default).
    --[no-]musescore	    Deals with some peculiarities of MuseScore
			    generated XML. If not set, it will be
			    automatically detected.

  Miscellaneous options:

    --help  -h		this message
    --man		full documentation
    --ident		show identification
    --verbose		verbose information

=head1 DESCRIPTION

This program will read the given input file(s) and parse them. The
input files are assumed to contain valid iRealPro data as exported by
the iRealPro app on Android and iOS.

If Multiple input files are given, their contents will be combined
into a single playlist, named after the first playlist or, if the
first file contains a single song, the title of this song.

Finally, the resultant playlist is converted. Several conversions are
possible:

=over 8

=item PDF

Produces a single PDF document containing a nicely formatted version
of the songs.

=item PNG

Produces one or more PNG files, one for each song. The contents of the
PNG is visually identical to the PDF.

Optionally, a 'near pixel perfect' PNG may be produced that is near
pixel perfect identical to the images generated by the iRealPro app.
See the B<--npp> option for details.

See also L<NPP IMAGING>.

If multiple output pages are to be generated you can add a sprintf()
compliant %d sequence in the output file name. For example, with
B<--output=img%04d.png> output files will be B<img0001.png>,
B<img0002.png>, and so on.

=item JSON

This is basically a low-level representation of the contents of the
songs.

=item TEXT

This is a textual, editable representation of the contents of the
songs. It may be edited and used as input to this program for further
processing.

=item HTML

A single HTML document very similar to the documents exported by the
iRealPro app itself.

Optionally, a playlist can be split (see B<--split>) into a series of
HTML documents each containing one song. The documents are named after
the song title and can be stored in a separate directory (see
B<--dir>).

=back

=head1 OPTIONS

=over 8

=item B<--output=>I<XXX>

Specifies the desired output file name.

The file name extension controls the output type. 

=item B<--select=>I<NN>

Selects a single song from a playlist.

=item B<--list>

Prints the titles of the songs from a playlist.

Output defaults to standard output.

=item B<--split>

Splits the songs from a playlist into individual HTML files. Use
B<--dir> to control where the files will be written.

Note: B<--output> is ignored.

=item B<--dir=>I<XXX>

With B<--split>, specifies the directory where the individual HTML
files will be written.

=item B<--npp=>I<variant>

With PNG output, produces near pixel-perfect iRealPro output.

I<variant> must be 'hand' (for the hand-written style) or 'standard'.
iRealPro uses some non-hand symbols although hand-written versions are
available. To obtain this exact behaviour, set the variant to 'hand_strict'.

Add a minus at the end of the variant to select to get minor chords
with an 'm' instead of the default '-'.

See also L<NPP IMAGING>.

=item B<--transpose=[+-]NN>  B<-x>

Transposes up/down semitones.

Currently implemented for PDF and PNG output only.

=item B<--[no]toc>

With PDF output, produces or suppresses the table of contents.

By default, A ToC is automatically generated if a playlist
contains more than one song.

=item B<-->[B<no->]B<suppress-upbeat>

With MusicXML input, suppresses an initial upbeat. iRealPro doesn't
deal with upbeats anyway.

This is enabled by default.

=item B<-->[B<no->]B<override-alt>

With MusicXML input, replaces series of alt modifications (e.g.
C<7b5#5b9#9>) with C<alt>.

This is enabled by default.

=item B<-->[B<no->]B<condense>

With MusicXML input, uses condensed chords when there may not be
sufficient space to show a chord without overlapping.

This is enabled by default.

=item B<-->[B<no->]B<suppress-text>

With MusicXML input, ignore the directives written on top of or below
the staffs. Often these texts lead to unreadable results.

=item B<-->[B<no->]B<musescore>

With MusicXML input, deals with a number of peculiarities in the XML
as generated by MuseScore. This implies b<--supress-text>.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item I<file>

The input file(s) to process.

=back

=head1 NPP IMAGING

To enable pixel perfect images some proprietary files from the
iRealPro app are required. For copyright reasons, these files cannot
be included with this program.

The necessary files can be found in the iRealPro APK, folder
res/drawable-nodpi-v4. Just copy these files to the
res/drawable-nodpi-v4 folder of irealcvt and NPP imaging should be
functional.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-irealpro at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-iRealPro>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this program with the perldoc command.

    perldoc irealcvt

=head1 ACKNOWLEDGEMENTS

Massimo Biolcati of Technimo LLC, for writing iRealPro.

The iRealPro community, for contributing many, many songs.

=head1 COPYRIGHT & LICENSE

Copyright 2013,2016 Johan Vromans, all rights reserved.

Clone me at L<GitHub|https://github.com/sciurius/perl-Data-iRealPro>

=cut
