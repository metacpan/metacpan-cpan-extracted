#! perl

package App::PDF::Link;

# pdflink -- insert file links in PDF documents

our $VERSION = '0.18';

# Author          : Johan Vromans
# Created On      : Thu Sep 15 11:43:40 2016
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar 20 09:36:20 2017
# Update Count    : 316
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use utf8;
use Carp;

################ The Process ################

use App::PDF::Link::Icons;
use PDF::API2 2.029;
use Encode qw (encode_utf8 decode_utf8 );

sub run {
    my ( $pkg, $env ) = @_;

    use PDF::API2::Annotation;
    die("No attachment support??")
      unless PDF::API2::Annotation->can( $env->{embed}
					 ? "fileattachment" : "file" );

    use PDF::API2::Page;
    *PDF::API2::Page::annotation =
      *PDF::API2::Page::annotation_xx;

    if ( @{ $env->{targets} } ) {
	linktargets( $env, $_, $env->{targets} )
	  foreach @ARGV;
    }
    else {
	linkit( $env );
    }
}

################ Subroutines ################

sub linktargets {
    my $env = shift;
    my ( $pdf, $pageno, $pdfname, $targets, @targets );
    my ( $v, $d, $p );

    if ( @_ == 2 ) {
	( $pdfname, $targets ) = @_;

	warn("Loading PDF $pdfname...\n") if $env->{verbose};
	$pdf = PDF::API2->open($pdfname)
	  or die("$pdfname: $!\n");

	( $v, $d, $p ) = File::Spec->splitpath($pdfname);
	my $pp = $p;
	$pp =~ s/\.pdf$//i;

	@targets = @$targets;
	foreach ( @targets ) {
	    $_ = $pp . $_ if /^\.\w+$/;
	}
    }
    elsif ( @_ == 3 ) {
	( $pdf, $pageno, $targets ) = @_;
	@targets = @$targets;
    }
    else {
	die("Internal error -- wrong vall to linktargets\n");
    }

    my $page;			# the current page
    my $text;			# text content
    my $gfx;			# graphics content
    my $x;			# current x for icon
    my $y;			# current y for icon
    my $did;
    my $embed = $env->{embed};

    foreach ( @targets ) {
	unless ( -r $_ ) {
	    warn("\tTarget: ", encode_utf8($_), " missing (skipped)\n");
	    next;
	}
	$did++;

	my $t = substr( $_, length(File::Spec->catpath($v, $d||"", "") ) );
	( my $ext = $t ) =~ s;^.*\.(\w+)$;$1;;
	my $p = get_icon( $env, $pdf, $ext );
	my $action =
	  $p
	    ? $embed
	      ? $embed == 2 ? "attached" : "embedded"
	      : "linked"
	    : "ignored";

	if ( $env->{verbose} ) {
	    warn("\tFile: ", encode_utf8($t), " ($action)\n");
	}
	next unless $p;

	my $dx = $env->{iconsz} + $env->{padding};
	my $dy = $env->{iconsz} + $env->{padding};

	unless ( $page ) {
	    $page = $pdf->openpage($pageno);
	    my @m = $page->get_mediabox;
	    if ( $env->{xpos} >= 0 ) {
		$x = $m[0] + $env->{xpos};
	    }
	    else {
		$x = $m[2] + $env->{xpos} - $env->{iconsz};
		$dx = -$dx unless $env->{vertical};
	    }
	    if ( $env->{ypos} >= 0 ) {
		$y = $m[3] - $env->{ypos} - $env->{iconsz};
	    }
	    else {
		$y = $m[1] - $env->{ypos};
		$dy = -$dy if $env->{vertical};
	    }

	    $text = $page->text;
	    ####WARNING: Coordinates may be wrong!
	    # The graphics context uses the user transformations
	    # currently in effect. If these were not neatly restored,
	    # the graphics may be misplaced/scaled.
	    # By using --gfunder, the images are placed behind the page
	    # but this only works for transparent pages.
	    $gfx = $page->gfx( $embed ? 0 : $env->{gfunder} );
	}

	my $border = $env->{border};
	my @r = ( $x, $y, $x + $env->{iconsz}, $y + $env->{iconsz} );
	my $ann;
	$ann = $page->annotation_xx;
	if ( $embed ) {
	    # This always uses the right coordinates.
	    $ann->fileattachment( $t,
				  -text => "$t $action by pdflink $VERSION",
				  $embed == 1 ? ( -icon => $p ) : (),
				  -rect => \@r );
	}
	else {
	    $ann->file( $t, -rect => \@r );
	    my $scale = $env->{iconsz} / $p->width;
	    $gfx->image( $p, @r[0,1], $scale );
	}

	if ( $env->{border} ) {
	    $gfx->rectxy(@r );
	    $gfx->stroke;
	}

	# Next link.
	if ( $env->{vertical} ) {
	    $y -= $dy;
	}
	else {
	    $x += $dx;
	}
    }
    return unless $pdfname;

    # Finish PDF document.
    if ( $env->{output} ) {
	warn("Writing PDF ", $env->{output}, " ...\n") if $env->{verbose};
	$pdf->saveas($env->{output});
	warn("Wrote: ", $env->{output}, "\n") if $env->{verbose};
    }
    elsif ( $did ) {
	warn("Updating PDF $pdfname...\n") if $env->{verbose};
	$pdf->update;
	warn("Wrote: $pdfname\n") if $env->{verbose};
    }
    else {
	warn("Not modified: $pdfname\n") if $env->{verbose};
    }
}

sub linkit {
    my $env = shift;

    require Text::CSV_XS;
    require File::Spec;
    require File::Glob;

    my ( $pdfname, $csvname ) = @ARGV;
    unless ( $csvname ) {
	( $csvname = $pdfname ) =~ s/\.pdf$/.csv/i;
    }
    $env->{output} ||= "__new__.pdf";

    warn("Loading PDF $pdfname...\n") if $env->{verbose};
    my $pdf = PDF::API2->open($pdfname)
      or die("$pdfname: $!\n");

    my ( $v, $d, $p ) = File::Spec->splitpath($pdfname);
    my $pp = $p;
    $pp =~ s/\.pdf$//i;

    # Read/parse CSV.
    warn("Loading CSV $csvname...\n") if $env->{verbose};
    my $csv = Text::CSV_XS->new( { binary => 1,
				   sep_char => ";",
				   empty_is_undef => 1,
				   auto_diag => 1 });
    open( my $fh, "<:encoding(utf8)", $csvname )
      or die("$csvname: $!\n");

    my $i_title;
    my $i_pages;
    my $i_xpos;
    my $i_ypos;
    my $row = $csv->getline($fh);
    for ( my $i = 0; $i < @$row; $i++ ) {
	next unless defined $row->[$i];
	$i_title = $i if lc($row->[$i]) eq "title";
	$i_pages = $i if lc($row->[$i]) eq "pages";
	$i_xpos  = $i if lc($row->[$i]) eq "xpos";
	$i_ypos  = $i if lc($row->[$i]) eq "ypos";
    }
    die("Invalid info in $csvname. missing TITLE\n")
      unless defined $i_title;
    die("Invalid info in $csvname. missing PAGES\n")
      unless defined $i_pages;

    warn("Processing CSV entries...\n") if $env->{verbose};
    while ( $row = $csv->getline($fh)) {
	my $title = $row->[$i_title];
	my $pageno = $row->[$i_pages];
	$pageno = $1 if $pageno =~ /^(\d+)/;
	warn("Page: $pageno, ", encode_utf8($title), "\n") if $env->{verbose};

	my $t = $title;
	$t =~ s;[:/];@;g;		# eliminate dangerous characters
	$t =~ s;["<>?\\|*];@;g if $^O =~ /win/i; # eliminate dangerous characters

	my @files = File::Glob::bsd_glob( File::Spec->catpath($v, $d, "$t.*" ) );
	linktargets( $env, $pdf, $pageno, \@files );

    }
    close $fh;

    # Finish PDF document.
    warn("Writing PDF ", $env->{output}, " ...\n") if $env->{verbose};
    $pdf->saveas($env->{output});
    warn("Wrote: ", $env->{output}, "\n") if $env->{verbose};
}

################ Options and Configuration ################

use Getopt::Long 2.13;
use File::Spec;
use Carp;

# Package name.
my $my_package;
# Program name and version.
my ($my_name, $my_version);

sub app_setup {
    my ( $pkg, $appname, $appversion, %args ) = @_;
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    # Package name.
    $my_package = $args{package};
    # Program name and version.
    if ( defined $appname ) {
	($my_name, $my_version) = ($appname, $appversion);
    }
    else {
	($my_name, $my_version) = qw( MyProg 0.01 );
    }

    my $options =
      {
       output		 => undef,	# output pdf
       embed		 => undef,	# link, embed or attach
       all		 => 0,		# link all files
       xpos		 => 60,		# position of icons
       ypos		 => 60,		# position of icons
       padding		 => 0,		# padding between icons
       iconsz		 => 50,		# desired icon size
       icons		 => {},		# additional icons
       vertical		 => undef,	# stacking of icons
       border		 => 0,		# draw borders around icon
       gfunder		 => 0,		# draw images behind the page
       targets		 => [],		# explicit link targets
       verbose		 => 0,		# verbose processing
       ### ADD OPTIONS HERE ###

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

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        require Pod::Find;
        Pod::Usage->import;
        &pod2usage( -input => Pod::Find::pod_where({-inc => 1}, __PACKAGE__), @_ );
    };

    # Collect command line options in a hash, for they will be needed
    # later.
    my $clo = {};

    # Sorry, layout is a bit ugly...
    if ( !GetOptions
	 ($clo,

	  ### ADD OPTIONS HERE ###
	  'output|pdf=s',
	  'embed',
	  'attach'	=>  sub { $clo->{embed} = 2 },
	  'all',
	  'xpos=i',
	  'ypos=i',
	  'iconsize|icon=i',
	  'icons=s%',
	  'padding=i',
	  'vertical',
	  'border',
	  'gfunder',
	  'targets|t=s@',

	  # Standard options.
	  'ident'		=> \$ident,
	  'help|?'		=> \$help,
	  'manual'		=> \$man,
	  'verbose',
	  'trace',
	  'debug',
	 ) )
    {
	$pod2usage->(2);
    }
    # GNU convention: message to STDOUT upon request.
    app_ident(\*STDOUT) if $ident or $help;
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }

    # Plug in command-line options.
    @{$options}{keys %$clo} = values %$clo;

    if ( @{ $options->{targets} } ) {
	@{ $options->{targets} } = split( /[;,]/, join(":", @{ $options->{targets} }) );
	$pod2usage->(1) unless @ARGV;
	$pod2usage->(1) if $options->{pdf} && @ARGV > 1;
    }
    else {
	$pod2usage->(1) if @ARGV < 1 || @ARGV > 2;
    }

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

=head1 NAME

pdflink - insert document links in PDF

=head1 SYNOPSIS

  pdflink [options] pdf-file [csv-file]

  pdflink [options] --targets=file1;file2 pdf-file [pdf-file ...]

Inserts document links in PDF

 Options:
    --output=XXX	name of the new PDF (default __new__.pdf)
    --embed		embed the data files instead of linking
    --attach		attach the data files instead of linking
    --xpos=NN		X-position for links
    --ypos=NN		Y-position for links relative to top
    --iconsize=NN	size of the icons, default 50
    --icons=type=XXX	add icon image XXX for this type
    --padding=NN	padding between icons, default 0
    --vertical		stacks icons vertically
    --border		draws a border around the links
    --gfunder		draws the images behind the page
    --targets=XXX	specifies the target(s) to link to
    --ident		shows identification
    --help		shows a brief help message and exits
    --man               shows full documentation and exits
    --verbose		provides more verbose information

=head1 DESCRIPTION

When invoked without a B<--targets> option, this program will process
the PDF document using the associated CSV as table of contents.

For every item in the PDF that has one or more additional files (files
with the same name as the title, but differing extensions), clickable
icons are added to the first page of the item. When clicked in a
suitable PDF viewing tool, the corrresponding file will be activated.

For example, if the CSV contains

  title;pages;
  Blue Moon;24;

And the following files are present in the current directory

  Blue Moon.html
  Blue Moon.mscz

Then two clickable icons will be added to page 24 of the document,
leading to these two files.

Upon completion, the updated PDF is written out under the specified name.

When invoked with the B<--targets> option, all specified PDF files get
links inserted to the targets on the first page. If there is only one
PDF file you can use the B<--pdf> option to designate the name of the
new PDF document, otherwise all PDF files are updated (rewritten.

=head1 OPTIONS

Note that all sizes and dimensions are in I<points> (72 points per inch).

=over 8

=item B<--pdf=>I<XXX>

Specifies the updated PDF to be written.

=item B<--embed>

Normally links are inserted into the PDF document that point to files
on disk. To use the links from the PDF document, the target files must
exist on disk.

With B<--embed>, the target files are embedded (as file attachments)
to the PDF document. The resultant PDF document will be usable on its
own, no other files needed.

=item B<--attach>

Like B<--embed>, but no custom icon is supplied.

=item B<--all>

Normally, only files with known types (extensions) are taken into
account. Currently, these are C<html> for iRealPro, C<mscz> for
MuseScore and C<mgu> and similar for Band in a Box.

With B<--all>, all files that have matching names will be processed.
However, files with unknown extensions will get a neutral document
icon.

=item B<--xpos=>I<NN>

Horizontal position of the icons.

If the value is positive, icon placement starts relative to the left
side of the page.

If the value is negative, icon placement starts relative to the right
side of the page.

Default is 0 (zero); icon placement begins against the left side of
the page.

Icons are always placed from the outside of the page towards the
inner side.

An I<xpos> value may also be specified in the CSV file, in a column
with title C<xpos>. If present, this value is added to position
resulting from the command line / default values.

=item B<--ypos=>I<NN>

If the value is positive, icon placement starts relative to the top
of the page.

If the value is negative, icon placement starts relative to the bottom
of the page.

Default is 0 (zero); icon placement begins against the top of the
page.

Icons are always placed from the outside of the page towards the
inner side.

An I<ypos> offset value may also be specified in the CSV file, in a
column with title C<ypos>. If present, this value is added to position
resulting from the command line / default values. This is especially
useful if there are songs in the PDF that do not start at the top of
the page, e.g., when there are multiple songs on a single page.

=item B<--iconsize=>I<NN>

Desired size of the link icons. Default is 50.

=item B<--padding=>I<NN>

Space between icons. Default is to place the icons adjacent to each
other.

=item B<--vertical>

Stacks the icons vertically.

=item B<--border>

Requests a border to be drawn around the links.

Borders are always drawn for links without icons.

=item B<--gfunder>

Drawing the icon images uses the page transformations in effect at the
end of the page. If these were not neatly restored, the graphics may
be misplaced/scaled/flipped.

By using B<--gfunder>, the images are placed behind the page
but this only works for transparent pages.

This option is only relevant when adding links to external files. With
B<--embed> the problem does not occur.

=item B<--targets=>I<FILE1> [ B<;> I<FILE2> ... ]

Explicitly specifies the target files to link to. In this case no CSV
is processed and the input PDF(s) are updated (rewritten) unless
B<--pdf> is used to designate the output PDF name.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item I<directory>

The directory to process. Defaults to the current directory.

=back

=head1 ICONS

B<pdflink> has a number of icons built-in for common file types.
Associations between a filename extension and an icon can be made with
the B<--icons> command line option.

For example,

  --icons=pdf=builtin:PDF

This will associate the built-in icon PDF with filename extension C<pdf>.

Alternatively, an image file may be specified to add user defined icons.

  --icons=pdf=builtin:myicons/pdficon.png

The following icons are built-in. By default, only MuseScore and
iRealPro icons are associated and all other filename extensions will
be skipped. When pdflink is run with command line option B<--all>, all
built-in icons will be associated and all matching files will get
linked.

=over

=item PDF

Associated to filename extension C<pdf> (generic PDF document).

=item PNG

Associated to filename extension C<png> (PNG image).

=item JPG

Associated to filename extensions C<jpg> and C<jpeg> (JPG image).

=item MuseScore

Associated to filename extension C<mscz> (MuseScore document).

=item iRealPro

Associated to filename extension C<html> (iRealPro link in HTML document).

While technically this is wrong, this is the way iRealPro data is
handled on Android and iPad.

=item BandInABox

Associated to filename extensions C<mgu>, C<mg1> and so on (Band-In-A-Box document).

=item Document

Fallback icon for unknown filename extensions.

=item Border

Alternative fallback icon for unknown filename extensions.

=back

=head1 LIMITATIONS

Some PDF files cannot be processed. If this happens, try converting
the PDF to PDF-1.4 or PDF/A.

Files with extension B<html> are assumed to be iRealPro files and will
get the iRealPro icon.

Unknown extensions will get an empty square box instead of an icon.

Since colon C<:> and slash C</> are not allowed in file names, they
are replaced with C<@> characters.

If the icons come out at the wrong place or upside down, try
B<--gfunder>.

=head1 AUTHOR

Johan Vromans E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT

Copyright 2016 Johan Vromans. All rights reserved.

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

################ Patches ################

package PDF::API2::Page;

sub annotation_xx {
    my ($self, $type, $key, $obj) = @_;

    $self->{'Annots'}||=PDFArray();
    $self->{'Annots'}->realise if(ref($self->{'Annots'})=~/Objind/);
    if($self->{'Annots'}->is_obj($self->{' apipdf'}))
    {
#        $self->{'Annots'}->update();
    }
    else
    {
        $self->update();
    }

    my $ant=PDF::API2::Annotation->new;
    $self->{'Annots'}->add_elements($ant);
    $self->{' apipdf'}->new_obj($ant);
    $ant->{' apipdf'}=$self->{' apipdf'};
    $ant->{' apipage'}=$self;

    if($self->{'Annots'}->is_obj($self->{' apipdf'}))
    {
        $self->{' apipdf'}->out_obj($self->{'Annots'});
    }

    return($ant);
}

package PDF::API2::Annotation;

#=item $ant->fileattachment $file, %opts 
#
#Defines the annotation as a file attachment with file $file and
#options %opts (-rect, -border, -content (type), -icon (name), -text (comment)).
#
#=cut

sub fileattachment {
    my ( $self, $file, %opts ) = @_;

    my $icon;
    $icon = $opts{-icon} || 'PushPin' if exists $opts{-icon};
    my @r = @{ $opts{-rect}   } if defined $opts{-rect};
    my @b = @{ $opts{-border} } if defined $opts{-border};

    $self->{Subtype} = PDFName('FileAttachment');
    $self->{T} = PDFStr($opts{"-text"}) if exists($opts{"-text"});

    if ( is_utf8($file)) {
	# URI must be 7-bit ascii
	utf8::downgrade($file);
    }

    # 9 0 obj <<
    #    /Type /Annot
    #    /Subtype /FileAttachment
    #    /Name /PushPin
    #    /C [ 1 1 0 ]
    #    /Contents (test.txt)
    #    /FS <<
    #        /Type /F
    #        /EF << /F 10 0 R >>
    #        /F (test.txt)
    #    >>
    #    /Rect [ 100 100 200 200 ]
    #    /Border [ 0 0 1 ]
    # >> endobj
    #
    # 10 0 obj <<
    #    /Type /EmbeddedFile
    #    /Length ...
    # >> stream
    # ...
    # endstream endobj

    $self->{Contents} = PDFStr($file);
    # Name will be ignored if there is an AP.
    $self->{Name} = PDFName($icon) if $icon && !ref($icon);
    # $self->{F} = PDFNum(0b0);
    $self->{C} = PDFArray( map { PDFNum($_) } 1, 1, 0 );

    # The File Specification.
    $self->{FS} = PDFDict();
    $self->{FS}->{F} = PDFStr($file);
    $self->{FS}->{Type} = PDFName('F');
    $self->{FS}->{EF} = PDFDict($file);
    $self->{FS}->{EF}->{F} = PDFDict($file);
    $self->{' apipdf'}->new_obj($self->{FS}->{EF}->{F});
    $self->{FS}->{EF}->{F}->{Type} = PDFName('EmbeddedFile');
    $self->{FS}->{EF}->{F}->{' streamfile'} = $file;

    # Set the annotation rectangle and border.
    $self->rect(@r) if @r;
    $self->border(@b) if @b;

    # Set the appearance.
    $self->appearance($icon, %opts) if $icon;

    return($self);
}

sub appearance {
    my ( $self, $icon, %opts ) = @_;

    return unless $self->{Subtype}->val eq 'FileAttachment';

    my @r = @{ $opts{-rect}} if defined $opts{-rect};
    die "insufficient -rect parameters to annotation->appearance( ) "
      unless(scalar @r == 4);

    # Handle custom icon type 'None'.
    if ( $icon eq 'None' ) {
        # It is not clear what viewers will do, so provide an
        # appearance dict with no graphics content.

	# 9 0 obj <<
	#    ...
	#    /AP << /D 11 0 R /N 11 0 R /R 11 0 R >>
	#    ...
	# >>
	# 11 0 obj <<
	#    /BBox [ 0 0 100 100 ]
	#    /FormType 1
	#    /Length 6
	#    /Matrix [ 1 0 0 1 0 0 ]
	#    /Resources <<
	#        /ProcSet [ /PDF ]
	#    >>
	# >> stream
	# 0 0 m
	# endstream endobj

	$self->{AP} = PDFDict();
	my $d = PDFDict();
	$self->{' apipdf'}->new_obj($d);
	$d->{FormType} = PDFNum(1);
	$d->{Matrix} = PDFArray( map { PDFNum($_) } 1, 0, 0, 1, 0, 0 );
	$d->{Resources} = PDFDict();
	$d->{Resources}->{ProcSet} = PDFArray( map { PDFName($_) } qw(PDF));
	$d->{BBox} = PDFArray( map { PDFNum($_) } 0, 0, $r[2]-$r[0], $r[3]-$r[1] );
	$d->{' stream'} = "0 0 m";
	$self->{AP}->{N} = $d;	# normal appearance
	# Should default to N, but be sure.
	$self->{AP}->{R} = $d;	# Rollover
	$self->{AP}->{D} = $d;	# Down
    }

    # Handle custom icon.
    elsif ( ref $icon ) {
        # Provide an appearance dict with the image.

	# 9 0 obj <<
	#    ...
	#    /AP << /D 11 0 R /N 11 0 R /R 11 0 R >>
	#    ...
	# >>
	# 11 0 obj <<
	#    /BBox [ 0 0 1 1 ]
	#    /FormType 1
	#    /Length 13
	#    /Matrix [ 1 0 0 1 0 0 ]
	#    /Resources <<
	#        /ProcSet [ /PDF /Text /ImageB /ImageC /ImageI ]
	#        /XObject << /PxCBA 7 0 R >>
	#    >>
	# >> stream
	# q /PxCBA Do Q
	# endstream endobj

	$self->{AP} = PDFDict();
	my $d = PDFDict();
	$self->{' apipdf'}->new_obj($d);
	$d->{FormType} = PDFNum(1);
	$d->{Matrix} = PDFArray( map { PDFNum($_) } 1, 0, 0, 1, 0, 0 );
	$d->{Resources} = PDFDict();
	$d->{Resources}->{ProcSet} = PDFArray( map { PDFName($_) } qw(PDF Text ImageB ImageC ImageI));
	$d->{Resources}->{XObject} = PDFDict();
	my $im = $icon->{Name}->val;
	$d->{Resources}->{XObject}->{$im} = $icon;
	# Note that the image is scaled to one unit in user space.
	$d->{BBox} = PDFArray( map { PDFNum($_) } 0, 0, 1, 1 );
	$d->{' stream'} = "q /$im Do Q";
	$self->{AP}->{N} = $d;	# normal appearance

	if ( 0 ) {
	    # Testing... Provide an alternative for R and D.
	    # Works only with Adobe Reader.
	    $d = PDFDict();
	    $self->{' apipdf'}->new_obj($d);
	    $d->{Type} = PDFName('XObject');
	    $d->{Subtype} = PDFName('Form');
	    $d->{FormType} = PDFNum(1);
	    $d->{Matrix} = PDFArray( map { PDFNum($_) } 1, 0, 0, 1, 0, 0 );
	    $d->{Resources} = PDFDict();
	    $d->{Resources}->{ProcSet} = PDFArray( map { PDFName($_) } qw(PDF));
	    $d->{BBox} = PDFArray( map { PDFNum($_) } 0, 0, $r[2]-$r[0], $r[3]-$r[1] );
	    $d->{' stream'} =
	      join( " ",
		    # black outline
		    0, 0, 'm',
		    0, $r[2]-$r[0], 'l',
		    $r[2]-$r[0], $r[3]-$r[1], 'l',
		    $r[2]-$r[0], 0, 'l',
		    's',
		  );
        }

	# Should default to N, but be sure.
	$self->{AP}->{R} = $d;	# Rollover
	$self->{AP}->{D} = $d;	# Down
    }

    return $self;
}

1;
