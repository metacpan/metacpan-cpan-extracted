#! perl

# Data::iRealPro::Output::Imager - produce images for iRealPro songs

# Author          : Johan Vromans
# Created On      : Fri Jan 15 19:15:00 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Oct 30 10:28:19 2018
# Update Count    : 1517
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;
use App::Packager;
use FindBin;

package Data::iRealPro::Output::Imager;

use parent qw( Data::iRealPro::Output::Base );

our $VERSION = "1.00";

use Data::Dumper;
use Text::CSV_XS;
use Encode qw( encode_utf8 );

use constant FONTSX => 0;

sub new {
    my ( $pkg, $options ) = @_;

    my $self = bless( { variant => "irealpro" }, $pkg );

    # Get the resource dir.
    $self->{resdir} = $ENV{RESDIR};
    if ( $App::Packager::PACKAGED ) {
	$self->{resdir} ||= App::Packager::GetResourcePath();
    }
    else {
	$self->{resdir} ||= "$FindBin::Bin/../res";
    }
    $self->{resdir} .= "/";
    $self->{resdir} =~ s;/+$;/;;

    # Fonts resource dir.
    $self->{fontdir} = $ENV{FONTDIR} || $self->{resdir} . "/fonts";
    $self->{fontdir} .= "/";
    $self->{fontdir} =~ s;/+$;/;;

    if ( $options->{npp} ) {
	die( "Unsupported output type for NPP. Please select PNG or JPG.\n")
	  unless $options->{output} =~ /\.(jpg|png)$/i;
	if ( $options->{npp} =~ s/_strict// ) {
	    $options->{npp_strict} = 1;
	}
	if ( $options->{npp} =~ s/-$// ) {
	    $options->{npp_minor} = '';
	}
	else {
	    $options->{npp_minor} = 'm';
	}
	$options->{npp} = 'straight' unless $options->{npp} eq 'hand';
	$self->{prefab} = $self->{resdir} . "/drawable-nodpi-v4/";
	# Quality_H is the 'missing symbol' symbol. It better be there.
	if ( -s $self->{prefab} . "quality_h" .
	        ( $options->{npp} eq 'hand' ? "_hand" : "" ) .
	         ".png" ) {
	}
	else {
	    die( "NPP Image generation not available" );
	}
	warn("Using NPP images from ", $self->{prefab}, "\n")
	  if $options->{verbose};
    }

    for ( qw( trace debug verbose output variant transpose toc crop
	      npp npp_minor npp_strict
	   ) ) {
	$self->{$_} = $options->{$_} if exists $options->{$_};
    }
    $self->{npp} ||= 0;

    # Scaling (bitmaps only).
    if ( $options->{npp} ) {
	no warnings 'redefine';
	eval( "sub scale(\$) { \$_[0] };" );
    }
    elsif ( $options->{scale} && $options->{scale} =~ /^[\d.]+$/ ) {
	no warnings 'redefine';
	eval( "sub scale(\$) { " . $options->{scale} . "*\$_[0] };" );
    }
    return $self;
}

sub options {
    my $self = shift;
    [ @{ $self->SUPER::options }, qw( transpose npp ) ];
}

# A4 image format.
use constant PAGE_WIDTH  => 595;
use constant PAGE_HEIGHT => 842;

# NPP operations are done on a fixed canvas. Eventually, the result
# will be scaled or split to match the desired output dimensions.

use constant CANVAS_WIDTH  => 1920;
use constant CANVAS_HEIGHT => 2480;

# Scaling for bitmap graphics to get finer images. Not for NPP.
sub scale($) { 2*$_[0] };

# Fonts.
my $_default_font = "DroidSans.ttf";
#my $_default_font = "DroidSansAll.ttf";
my $fonts =
  {
    titlefont => $_default_font,
    stitlefont => $_default_font,
    textfont  => $_default_font,
    markfont  => "DroidSans-Bold.ttf",
    # Normal and condensed versions
    chordfont => "Myriad-CnSemibold.ttf",
    chrdfont  => "Myriad-UcnSemibold.ttf",
#    chordfont => "FreeSansBold.ttf",
#    chrdfont  => "FreeSansCn.ttf",
    musicfont => "Bravura.ttf",
    muscfont  => "BravuraCn.ttf",
  };

# Colors.
my $black = "#000000";
my $red   = "#ff0000";
my $blue  = "#0000ff";

sub process {
    my ( $self, $u, $options ) = @_;
    # {{{

    my $plname = $u->{playlist}->{name};

    # If it is a playlist, assume multiple songs.
    # With --output this must be either a PDF, or
    # contain %d or %t.
    if ( $plname && @{ $u->{playlist}->{songs} } > 1 ) {
	if ( $self->{output}
	     && $self->{output} !~ /\%\d*[dt]/
	     && $self->{output} !~ /\.pdf$/i ) {
	    die("Can only generate PDF for playlist\n");
	}
	warn( "PLAYLIST: $plname, ",
	      scalar(@{ $u->{playlist}->{songs} }), " songs\n" )
	  if $options->{verbose};
	( my $t = $plname ) =~ s/[ \/:"]/_/g;
	$self->{output} ||= "$t.pdf";
	$self->{toc} = 1 unless defined $self->{toc};
    }
    $self->{output} ||= "__new__.pdf";

    ( my $outtype = lc($self->{output}) ) =~ s/^.*\.(.+)$/$1/;
    $self->{outtype} = $outtype;

    if ( $outtype eq "pdf" ) {
	if ( eval { require PDF::API2 } ) {
	    $self->{pdf} = PDF::API2->new;
	    #	$self->{pdf}->mediabox( 0, PAGE_HEIGHT, PAGE_WIDTH, 0 );
	    $self->{pdf}->mediabox( 0, 0, PAGE_WIDTH, PAGE_HEIGHT );
	}
	else {
	    die( "PDF output requires module PDF::API2 to be installed.\n" );
	}
    }
    elsif ( $outtype =~ /^png|jpg$/ ) {
	if ( eval { require Imager } ) {
	    # ok
	}
	else {
	    die( "PNG and JPG output require module Imager to be installed.\n" );
	}
    }
    else {
	die( "Unsupported output type for ", $self->{output}, "\n" );
    }

    my $pageno = 1;

    my $csv;
    my $csv_fd;
    my $csv_name;
    if ( $outtype eq "pdf"
	 && @{ $u->{playlist}->{songs} } > 1 ) {
	$csv_name = $self->{output};
	$csv_name =~ s/\.pdf$/.csv/i;
	open( $csv_fd, ">:encoding(utf8)", $csv_name );
	$csv = Text::CSV_XS->new( { binary => 1,
				    quote_space => 0,
				    sep_char => ";" } );
	$csv->print( $csv_fd,
		     [ qw( title pages keys composers
			   collections ), "source types" ] );
	$csv_fd->print("\n");
    }

    # Process the song(s).
    my $songix;
    my @book;
    foreach my $song ( @{ $u->{playlist}->{songs} } ) {
	$songix++;
	warn( sprintf("Song %3d: %s\n", $songix, $song->{title}) )
	  if $self->{verbose};
	push( @book, [ $song->{title}, $pageno ] );
	my $mx = $self->decode_song($song);

	$self->{songix} = $songix;
	my $numpages = $self->make_image( $song, $mx );

	next unless $csv_fd;

	my $pages = $pageno;
	if ( $numpages > 1 ) {
	    $pages .= "-" . ( $pageno + $numpages - 1 );
	    $pageno += $numpages;
	}
	else {
	    $pageno++;
	}
	my $key = $song->{key};
	$key =~ s/-$/m/;
	my $composer = $song->{composer};
	# $composer = "$2 $1" if $composer =~ /^(.+?) +([^ ]+)$/;
	$csv->print( $csv_fd,
		     [ $song->{title},
		       $pages,
		       $key,
		       $composer,
		       $plname,
		       "Sheet Music",
		     ] );
	$csv_fd->print("\n");
    }

    if ( $outtype eq "pdf" ) {
	$pageno += $self->toc( $plname, \@book ) if $self->{toc};
	$self->{pdf}->saveas($self->{output});
	warn( "Wrote: ", $self->{output}, "\n" ) if $self->{verbose};
	if ( $csv_fd ) {
	    $csv_fd->close;
	    warn( "Wrote: $csv_name\n" ) if $self->{verbose};
	}
    }
    # }}}
}

sub decode_song {
    my ( $self, $song ) = @_;

    # Get the tokens array. This reflects as precisely as possible
    # the contents of the pure data string.
    if ( $self->{debug} ) {
	my $tokens = $song->tokens;
	warn(Dumper($tokens));
    }

    # Then create array of cells.
    my $cells = $song->cells;
    if ( $self->{debug} ) {
	warn Dumper($cells);
	warn('$DATA = "', $song->{data}, "\";\n");
    }

    $cells;
}


my %smufl =
  ( brace		=> "\x{e000}",
    reversedBrace	=> "\x{e001}",
    barlineSingle	=> "\x{e030}",
    barlineDouble	=> "\x{e031}",
    barlineFinal	=> "\x{e032}",
# repeatLeft and Right are too wide. Use a substitute.
#   repeatLeft		=> "\x{e040}",
#   repeatRight		=> "\x{e041}",
#   repeatRightLeft	=> "\x{e042}",
    repeatLeft		=> "\x{e000}\x{e043}", # {:
    repeatRight		=> "\x{e043}\x{e001}", # :}
    repeatRightLeft	=> "\x{e043}\x{e001}\x{e000}\x{e043}", # :}{:
    repeatDots		=> "\x{e043}",
    dalSegno		=> "\x{e045}",
    daCapo		=> "\x{e046}",
    segno		=> "\x{e047}",
    coda		=> "\x{e048}",
    timeSig0		=> "\x{e080}", # timeSig1, ...etc...
    flat		=> "\x{e260}",
    sharp		=> "\x{e262}",
    fermata		=> "\x{e4c0}",
    repeat1Bar		=> "\x{e500}",
    repeat2Bars		=> "\x{e501}",
    repeat4Bars		=> "\x{e502}",
    csymDiminished	=> "\x{e870}",
    csymHalfDiminished	=> "\x{e871}",
    csymAugmented	=> "\x{e872}",
    csymMajorSeventh	=> "\x{e873}",
    csymMinor		=> "\x{e874}",
  );

my $numrows = 16;
my $numcols = 16;

use constant CHORD_NORMAL      => 0x00;
use constant CHORD_CONDENSED   => 0x01;
use constant CHORD_ALTERNATIVE => 0x02;

# Generalized formatter for PDF::API2 and Imager.
sub make_image {
    # {{{
    my ( $self, $song, $cells ) = @_;

    my ( $lm, $tm, $rm, $bm, $dx, $dy );

    if ( $self->{npp} ) {
	$lm = 68;
	$rm = 0;		# unused
	$tm = 208;
	$dx = ( CANVAS_WIDTH - $lm - 18 ) / 16;
	$dy = 296;
	if ( $self->{npp} eq 'hand' ) {
	    $fonts->{titlefont} =
	      $fonts->{stitlefont} =
		$fonts->{textfont} =
		  "Felt-Regular.ttf";
	}

	# Calculate the required heigth and create the canvas.
	my $v = $tm;		# top margin
	$v += int( ( @$cells + 15 ) / $numcols ) * $dy; # cells
	$v += $cells->[-1]->vs * 121;	       # extra
	$v = CANVAS_HEIGHT if $v < CANVAS_HEIGHT; # minimal
	$self->{im} = Imager->new( xsize => CANVAS_WIDTH,
				   ysize => $v,
				   model => 'rgba',
				 );
    }
    else {
	$lm = 40;
	$rm = PAGE_WIDTH - $lm;
	$bm = PAGE_HEIGHT - 50;
	$tm = 172 - 50;
	$dx = ( $rm - $lm ) / $numcols;
	$dy = ( $bm - $tm ) / $numrows;

	if ( ! $self->{pdf} ) {
	    $self->{im} =
	      Imager->new( xsize => scale(PAGE_WIDTH),
			   ysize => scale(PAGE_HEIGHT),
			   model => 'rgb',
			 );
	}
    }
    die("Imager failure")
      unless $self->{pdf} || $self->{im};

    # Create fonts.
    $self->initfonts;

    my $textfont  = $self->{textfont};
    my $chordfont = $self->{chordfont};
    my $chrdfont  = $self->{chrdfont};
    my $musicfont = $self->{musicfont};
    my $muscfont  = $self->{muscfont};
    my $markfont  = $self->{markfont};

    my $musicglyphs = $self->{musicglyphs};
    my $musicsize = $self->{musicsize};
    my $chordsize = $self->{chordsize};

    if ( $dy < 1.6*$musicsize ) {
	$dy = 1.6*$musicsize;
    }
    my %missing_glyphs;

    $self->{pages} = 0;

    # Draw headings for a new page.
    my $newpage = sub {
	$self->newpage;

	my $titlesize = $self->{titlesize};
	my $titlefont = $self->{titlefont};
	my $stitlesize = $self->{stitlesize};
	my $stitlefont = $self->{stitlefont};
	my $ddx = 0.15*$musicsize;

	my @arg = ( ($lm+$rm)/2-$ddx, $tm-80, $song->{title},
		    $titlesize, $titlefont );
	@arg[0,1] = ( CANVAS_WIDTH/2, 75 ) if $self->{npp};
	$self->textc(@arg);

	if ( $song->{style} ) {
	    @arg = ( $lm-$ddx, $tm-50, "(".$song->{style}.")",
		     $stitlesize, $stitlefont );
	    @arg[0,1] = ( $lm + 10, 136 ) if $self->{npp};
	    $self->textl(@arg);
	}

	if ( $song->{composer} ) {
	    # If the composer is two words, assume lastname firstname.
	    # iRealPro swaps them.
	    my @t = split( ' ', $song->{composer} );
	    @t[0,1] = @t[1,0] if @t == 2;
	    @arg = ( $rm+$ddx, $tm-50, "@t",
		     $stitlesize, $stitlefont );
	    @arg[0,1] = ( CANVAS_WIDTH - 60, 134 ) if $self->{npp};
	    $self->textr(@arg);
	}

    };

    my $low;			# water mark to crop image

    # Discard final (trailing?) empty cells for a correct $low.
    # Note: Empty cells have just a 'vs' element.
    pop( @$cells )
      while $cells->[-1] && keys( %{ $cells->[-1] } ) == 1;

    # Process the cells.
    for ( my $i = 0; $i < @$cells; $i++ ) {
	# {{{
	# onpage is the cell index relative to the current page.
	# Note that we do not yet support multi-page songs.
	my $onpage = $i % ( $numrows * $numcols );
	if ( !$onpage ) {
	    # First cell on this page, draw headings and such.
	    $newpage->();
	    $low = 0;
	}

	# The current cell.
	my $cell = $cells->[$i];

	# Cell position on the drawing.
	my $x = $lm +    ( $onpage % $numcols ) * $dx;
	my $y = $tm + int( $onpage / $numcols ) * $dy;

	# Adjust vertical position.
	for ( $cell->vs ) {
	    next unless $_;
	    if ( $self->{npp} ) {
		$y += $_*121;
	    }
	    else {
		$y += $_*0.3*$dy;
	    }
	}

	# Adjust low water mark.
	if ( $y + $dy > $low ) {
	    $low = $y + $dy;
	}

	#### Cell contents ################

	for ( $cell->lbar ) {
	    next unless $_;

	    if ( $self->{npp} ) {
		$self->npp_bar( $x, $y, $_ );
		next;
	    }

	    my $col = /^repeat(?:Right)?Left$/ ? $red : $black;
	    $self->glyphc( $x, $y, $_, undef, $col );
	    next;
	}

	for ( $cell->rbar ) {
	    next unless $_;

	    if ( $self->{npp} ) {
		$self->npp_bar( $x+$dx, $y, $_ );
		next;
	    }

	    my $col = $black;
	    if ( /^repeatRight$/ ) {
		$col = $red;
		if ( ($i+1) % $numcols
		     && $i < @$cells-1
		     && $cells->[$i+1]->lbar
		     && $cells->[$i+1]->lbar eq "repeatLeft" ) {
		    $cells->[$i+1]->lbar = "repeatRightLeft";
		    next;
		}
	    }
	    $self->glyphc( $x+$dx, $y, $_, undef, $col );
	    next;
	}

	for ( $cell->time ) {
	    next unless $_;
	    my ( $t1, $t2 ) = @$_;
	    if ( $self->{npp} ) {
		$t2 = "" if $t1 == 12 && $t2 == 8;
		$self->npp_sig( $x, $y, "$t1$t2" );
		next;
	    }

	    my $w = $self->aw( $musicfont, 0.7*$musicsize,
			       $musicglyphs->{timeSig0} ) / 2;
	    # Move left half $w for centering, and half $w to get
	    # out of the way.
	    my $x = $x - $w - 0.15*$musicsize;
	    # An additinal half $w when double digits are involved.
	    $x -= $w/2 if $t1 > 10 || $t2 > 10;

	    # Transform ordinary digits into music glyphs.
	    $w = ord( $musicglyphs->{timeSig0} ) - ord("0");
	    $t1 =~ s/(\d)/sprintf( "%c",$w+ord($1) )/ge;
	    $t2 =~ s/(\d)/sprintf( "%c",$w+ord($1) )/ge;

	    $self->textc( $x, $y-0.55*$musicsize, $t1,
			  0.7*$musicsize, $musicfont, $red );
	    $self->textc( $x, $y-0.15*$musicsize, $t2,
			  0.7*$musicsize, $musicfont, $red );
	    next;
	}

	for ( $cell->sign ) {	# coda, segno, ...
	    next unless $_;
	    if ( $self->{npp} ) {
		$self->npp_sign( $x, $y, $_ );
		next;
	    }

	    $self->glyphl( $x+0.15*$musicsize, $y-1.05*$musicsize,
			   $_, 0.7*$musicsize, $red );
	    next;
	}

	for ( $cell->text ) {
	    next unless $_;
	    my ( $disp, $t ) = @$_;

	    if ( FONTSX ) {
		if ( $self->{pdf} ) {
		    # $textfont->{' font'} = Font::TTF::Font
		    for ( split( //, $t ) ) {
			next if $textfont->uniByEnc(ord($_));
			my $c = ord(substr($t,$i,1));
			next if $missing_glyphs{$c};
			$missing_glyphs{$c} = 1;
		    }
		}
		if ( $self->{im} ) {
		    my @c = $textfont->has_chars( string => $t );
		    for ( my $i = 0; $i < @c; $i++ ) {
			next if $c[$i];
			my $c = ord(substr($t,$i,1));
			next if $missing_glyphs{$c};
			$missing_glyphs{$c} = 1;
		    }
		}
	    }

	    my $hack;
	    # Sometimes, THAI PAIYANNOI (U+e2f) is abused as
	    # MUSICAL SYMBOL EIGHTH REST (u+1d13e).
	    $t =~ s/\x{e2f}/\x{1d13e}/g && $hack++;
	    # Likewise CYRILLIC SMALL LETTER GHE WITH UPTURN (U+491)
	    # -> MUSICAL SYMBOL QUARTER REST (U+1D13D)
	    $t =~ s/\x{491}/\x{1d13d}/g && $hack++;
	    # Likewise BOX DRAWINGS DOWN SINGLE AND LEFT DOUBLE (U+2555)
	    # -> MUSICAL SYMBOL SIXTEENTH REST (U+1D13F)
	    $t =~ s/\x{2555}/\x{1d13f}/g && $hack++;

	    # Displacement is 0 .. 74, in steps of 3.
	    if ($self->{npp} ) {
		$self->textl( $x-2, $y + $dy - 27 - ($dy / 74) * $disp, $t,
			      $hack ? 60 : 74, $textfont, $red );
		next;
	    }

	    $self->textl( $x+0.15*$musicsize,
			  $y+0.55*$musicsize-($disp/(45/$musicsize)),
			  $t, 0.55*$musicsize, $textfont, $red );
	    next;
	}

	for ( $cell->chord ) {	# chords and chordrepeats.
	    next unless $_;
	    my $c = $_;
	    my $font = $cell->sz ? $chrdfont : $chordfont;

	    if ( $c =~ /repeat\dBars?/ ) {

		# npp_strict
		#   both go at the border of this and the next cell
		# else
		#   1bar and 2bar not before barline: center in measure
		#   2bar before barline: center on barline

		if ( $self->{npp_strict} ) {
		    $x += $dx;
		    if (  $c eq "repeat1Bar" ) {
			$self->npp_repeat( $x, $y, 1 );
		    }
		    else {
			$self->npp_repeat( $x, $y, 2 );
		    }
		}
		elsif ( $c eq "repeat1Bar"
		     || ( $c eq "repeat2Bars" && !$cell->rbar )
		   ) {

		    # Find previous bar line.
		    my $pb = $i;
		    while ( $pb >= 0) {
			last if $cells->[$pb]->lbar
			  || ( $pb > 1 && $cells->[$pb-1]->rbar );
			$pb--;
		    }
		    # Find next bar line.
		    my $nb = $i;
		    while ( $nb < @$cells ) {
			last if $cells->[$nb]->rbar
			  || ( $nb+1 < @$cells && $cells->[$nb+1]->lbar );
			$nb++;
		    }

		    # Center between the barlines.
		    $x -= ( $i-$pb ) * $dx;
		    $x += ( $nb-$pb+1 ) * $dx/2;
		    if ( $self->{npp} ) {
			if (  $c eq "repeat1Bar" ) {
			    $self->npp_repeat( $x, $y, 1 );
			}
			else {
			    $self->npp_repeat( $x, $y, 2 );
			}
		    }
		    else {
			$self->textc( $x, ($y-0.3*$musicsize),
				      $musicglyphs->{$c}, $chordsize, $musicfont );
		    }
		}

		else {

		    # Find next bar line.
		    my $nb = $i;
		    while ( $nb < @$cells ) {
			last if $cells->[$nb]->rbar
			  || ( $nb+1 < @$cells && $cells->[$nb+1]->lbar );
			$nb++;
		    }

		    # Overprint next barline.
		    $x += ( $nb-$i+1 ) * $dx;
		    if ( $self->{npp} ) {
			$self->npp_repeat( $x, $y, 2 );
		    }
		    else {
			$self->textc( $x, ($y-0.3*$musicsize),
				      $musicglyphs->{$c}, $chordsize, $musicfont );
		    }
		}
		next;
	    }

	    if ( $c =~ /^repeat(Slash)$/ ) {
		if ( $self->{npp} ) {
		    $self->npp_slash( $x, $y );
		}
		else {
		    $self->textl( $x+0.4*$musicsize, $y, "/", $chordsize, $chordfont );
		}
		next;
	    }

	    if ( $self->{npp} ) {
		$self->npp_chord( $x, $y, $c,
				  $cell->sz ? CHORD_CONDENSED : CHORD_NORMAL );
	    }
	    else {
		$self->chord( $x+0.15*$musicsize, $y, $c, $musicsize, $font );
	    }
	    next;
	}

	for ( $cell->subchord ) {
	    next unless $_;
	    if ( $self->{npp} ) {
		$self->npp_chord( $x, $y, $_, CHORD_ALTERNATIVE );
	    }
	    else {
		$self->chord( $x+0.15*$musicsize, $y-$musicsize,
			      $_, 0.7*$chordsize );
	    }
	    next;
	}

	for ( $cell->alt ) {	# N1, N2, ... alternatives
	    next unless defined $_;
	    my $n = $_;
	    if ( $self->{npp} ) {
		$self->npp_ending( $x, $y, $n );
		next;
	    }

	    $self->textl( $x+0.15*$musicsize, $y-$musicsize, $n . ".",
			  0.55*$musicsize, $textfont, $red ) if $n;
	    $self->line( $x+0.1*$musicsize,
			 $y-$musicsize,
			 $x+0.1*$musicsize,
			 $y-1.5*$musicsize, $red );
	    $self->line( $x+0.1*$musicsize,
			 $y-1.5*$musicsize,
			 $x+2*$dx,
			 $y-1.5*$musicsize, $red );
	    next;
	}

	if ( $cell->flags && $cell->flags & 0x01 ) { # invisible END
	    next;				     # suppress.
	    my $disp = 0;
	    if ( $self->{npp} ) {
		$self->textl( $x-2, $y + $dy - 27 - ($dy / 74) * $disp,
			      "END", 60, $textfont, $blue );
		next;
	    }
	    $self->textl( $x+0.15*$musicsize,
			  $y+0.55*$musicsize-($disp/(45/$musicsize)),
			  "END", 0.5*$musicsize, $textfont, $blue );
	    next;
	}

	for ( $cell->mark ) {
	    next unless $_;
	    if ( $self->{npp} ) {
		$self->npp_mark( $x, $y, lc $_ );
		next;
	    }

	    my $t = $_;
	    $t = "In" if $t eq 'i';
	    $t = "V" if $t eq 'v';
	    $self->textl( $x-0.3*$musicsize, $y-0.9*$musicsize, $t,
			  0.6*$musicsize, $markfont, $red );
	    next;
	}

	next;
	# }}}
    }

    if ( FONTSX && %missing_glyphs ) {
	printf STDERR ( "Missing glyphs:" );
	printf STDERR ( " U+%04X", $_)
	  foreach sort map { abs($_) } keys %missing_glyphs;
	print STDERR ("\n");
    }

    # Crop excess bottom space.
    if ( $self->{im} && $self->{crop} && $low ) {
	$self->{im} = $self->{im}->crop( top => 0, height => scale($low) );
    }

    if ( $self->{outtype} =~ /^png|jpg$/ ) {
	my $did = 0;
	if ( $self->{npp} && $self->{im}->getheight > CANVAS_HEIGHT ) {
	    # Scale or split oversized pages.
	    if ( 1 ) {
		warn("Scaling output...\n") if $self->{verbose};
		$self->{im} =
		  $self->{im}->scale( xpixels => CANVAS_WIDTH,
				      ypixels => CANVAS_HEIGHT,
				      type => 'nonprop' );
	    }
	    else {
		my $x = $self->{im}->getheight;
		my $y = 0;
		my $p = 1;
		while ( $x > 0 ) {
		    my $im = Imager->new( xsize => CANVAS_WIDTH,
					  ysize => CANVAS_HEIGHT,
					  model => 'rgb' );
		    $im->box( filled => 1 );
		    $im->paste( src => $self->{im},
				src_minx => 0, src_miny => $y,
				src_maxx => CANVAS_WIDTH,
				src_maxy => $y + CANVAS_HEIGHT );
		    $x -= CANVAS_HEIGHT;
		    $y += CANVAS_HEIGHT;
		    my $of = $self->{output};
		    $of = sprintf( $of, $self->{songix} ) if $of =~ /\%\d*d/;
		    $of =~ s/\%t/$song->{title}/e;
		    $of =~ s/(\.\w+)$/sprintf("-%02d%s",$p,$1)/e;
		    $im->write( file => encode_utf8($of),
				type => $self->{outtype} );
		    warn( "Wrote: $of\n" ) if $self->{verbose};
		    $p++;
		}
		$did++;
	    }
	}
	unless ( $did ) {
	    my $of = $self->{output};
	    my $ot = $self->{outtype};
	    $ot = "jpeg" if $ot eq "jpg";
	    $of = sprintf( $of, $self->{songix} ) if $of =~ /\%\d*d/;
	    $of =~ s/\%t/$song->{title}/e;
	    $self->{im}->write( file => encode_utf8($of),
				type => $ot );
	    warn( "Wrote: $of\n" ) if $self->{verbose};
	}
    }

    # Return number of pages actually produced.
    # This will always be 1 unless generating PDF.
    $song->{pages} = $self->{pages};

    # }}}
}

# Draw a chord, with potentially a bass note.
sub chord {
    my ( $self, $x, $y, $c, $size, $font ) = @_;
    $font ||= $self->{chordfont};
    $size ||= $self->{chordsize};
    $c =~ s/\*(.*?)\*/$1/;
#    $c =~ s/-/m/;
    my $bass;
    if ( $c =~ m;(.*?)/(.*); ) {
	$bass = $2;
	$c = $1;
    }

    my $one = 0.05*$size;
    $y += $one;

    my @c = split ( //, $c );
    my $root = shift(@c);
    $root = " " if $root eq "W";
    if ( $root eq "N" and $c[0] eq "C" ) {
	shift(@c);
	$x += $self->textl( $x, $y, "N.C.", $size, $self->{chrdfont} );
    }
    else {
	$x += $self->textl( $x, $y, $root, 1.2*$size, $font );
    }

    if ( @c ) {
	if ( $c[0] eq "b" ) {
	    shift(@c);
	    $self->textl( $x+$one, $y-0.6*$size,
			  $self->{musicglyphs}->{flat},
			  $size, $self->{musicfont} );
	}
	elsif ( $c[0] eq "#" ) {
	    shift(@c);
	    $self->textl( $x+$one, $y-0.7*$size,
			  $self->{musicglyphs}->{sharp},
			  0.9*$size, $self->{musicfont} );
	}
    }

    while ( @c ) {
	my $c = shift(@c);
	if ( $c eq "b" ) {
	    $x += $self->glyphl( $x+$one, $y-0.15*$size, "flat", 0.8*$size );
	}
	elsif ( $c eq "#" ) {
	    $x += $self->glyphl( $x, $y-0.15*$size, "sharp", 0.6*$size );
	}
	elsif ( $c =~ /\d/ ) {
	    $x += $self->textl( $x, $y+0.1*$size, $c, 0.7*$size, $font );
	}
	elsif ( $c eq "^" ) {
	    $x += $self->textl( $x, $y,
			    $self->{musicglyphs}->{csymMajorSeventh},
			    0.8*$size, $self->{muscfont} );
	}
	elsif ( $c eq "o" ) {
	    $x += $self->textl( $x, $y,
				    $self->{musicglyphs}->{csymDiminished},
				    0.8*$size, $self->{muscfont} );
	}
	elsif ( $c eq "h" ) {
	    $x += $self->textl( $x, $y,
				    $self->{musicglyphs}->{csymHalfDiminished},
				    0.8*$size, $self->{muscfont} );
	}
	elsif ( $c eq "-" ) {
	    $x += $self->textl( $x, $y,
				    $self->{musicglyphs}->{csymMinor},
				    0.8*$size, $self->{muscfont} );
	}
	else {
	    $x += $self->textl( $x, $y+$one+$one, $c,
				    0.7*$size, $self->{chrdfont} );
	}
    }
    return unless $bass;
    my $w = $self->aw( $font, 0.9*$size, "/");
    $x -= $w/3;
    $y += 0.3*$size;
    $self->textl( $x, $y, "/", 0.9*$size, $font );
    $x += $w;
    $y += 0.2*$size;
    $self->chord( $x-$one, $y, $bass, 0.6*$size, $font );
}

sub font_bl {
    my ( $font, $size ) = @_;
    $size / ( 1 - $font->descender / $font->ascender );
}

sub toc {
    my ( $self, $plname, $book ) = @_;

    my $pages;
    my $textfont  = $self->{textfont};
    my $textsize = 10;

    my $lm = 40;
    my $rm = PAGE_WIDTH - $lm;
    my $bm = PAGE_HEIGHT - 50;
    my $tm = 80;
    my $x;
    my $y = PAGE_HEIGHT;	# force page break
    my $dy = 1.2 * $textsize;
    my $yb = font_bl( $textfont, $textsize );

    $pages = 0;

    # Draw headings for a new page.
    my $newpage = sub {
	$self->newpage;
	$pages++;
	if ( $pages == 1 ) {
	    my $titlesize = $self->{titlesize};
	    my $titlefont = $self->{titlefont};
	    $self->textc( ($lm+$rm)/2, $tm-25,
			  $plname || "Table of Contents",
			  $titlesize, $titlefont );
	}
	$x = $lm;
	$y = $tm;
    };

    foreach my $b ( @$book ) {

	if ( $y > $bm ) {
	    $newpage->();
	}
	$self->textr( $x+25, $y+$yb, $b->[1].".", $textsize, $textfont );
	$self->textl( $x+30, $y+$yb, $b->[0], $textsize, $textfont );
	my $ann = $self->{page}->annotation;
	$ann->link($self->{pdf}->openpage($b->[1]));
	$ann->rect( $x, PAGE_HEIGHT - $y,
		    $x+25+$self->aw( $textfont, $textsize, $b->[0] ),
		    PAGE_HEIGHT - ( $y + $textsize ) );
	$y += $dy;
    }

    return $pages;
}

# New page.
sub newpage {
    my ( $self ) = @_;
    $self->{pages}++;

    if ( $self->{im} ) {
	# Start with a white page.
	$self->{im}->box( filled => 1 );
    }

    if ( $self->{pdf} ) {
	$self->{page} = $self->{pdf}->page;
	$self->{text} = $self->{page}->text;
    }
};

################ Low level graphics ################

# String width.
sub aw {
    my ( $self, $font, $size, $t ) = @_;
    if ( $self->{im} ) {
	my @w = $font->bounding_box( size => $size, string => $t );
	# ($neg_width,
	#  $global_descent,
	#  $pos_width,
	#  $global_ascent,
	#  $descent,
	#  $ascent,
	#  $advance_width,
	#  $right_bearing)
	return $w[6];
    }
    if ( $self->{pdf} ) {
	$self->{text}->font( $font, $size );
	return $self->{text}->advancewidth($t);
    }
}

# Draw text, left aligned.
sub textl {
    my ( $self, $x, $y, $t, $size, $font, $col, $lcr ) = @_;
    $size ||= $self->{musicsize};
    $font ||= $self->{textfont};
    $col ||= $black;
    $lcr ||= 'l';

    my $w = $self->aw( $font, $size, $t );
    $x -= $w/2 if $lcr eq 'c';
    $x -= $w if $lcr eq 'r';

    if ( $self->{im} ) {
	$_ = scale($_) for $x, $y, $size;
	$self->{im}->string( font => $font, size => $size, aa => 1,
			     color => $col, x => $x, y => $y, text => $t );
    }
    if ( $self->{pdf} ) {
	for ( $self->{text} ) {
	    $_->translate( $x, PAGE_HEIGHT-$y );
	    $_->fillcolor($col) if $col ne $black;
	    $_->text($t);
	    $_->fillcolor($black) if $col ne $black;
	}
    }
    $w;
};

# Draw text, centered.
sub textc {
    my ( $self, $x, $y, $t, $size, $font, $col, $lcr ) = @_;
    $lcr ||= 'c';
    $self->textl( $x, $y, $t, $size, $font, $col, $lcr );
};

# Draw text, right aligned.
sub textr {
    my ( $self, $x, $y, $t, $size, $font, $col, $lcr ) = @_;
    $lcr ||= 'r';
    $self->textl( $x, $y, $t, $size, $font, $col, $lcr );
};

# Draw music glyph, centered.
sub glyphc {
    my ( $self, $x, $y, $smc, $size, $col ) = @_;
    $size ||= $self->{musicsize};
    die("Unknown glyph: $smc") unless exists $self->{musicglyphs}->{$smc};
    $self->textc( $x, $y+0.15*$self->{musicsize},
		  $self->{musicglyphs}->{$smc}, $size,
		  $self->{musicfont}, $col );
};

# Draw music glyph, left aligned.
sub glyphl {
    my ( $self, $x, $y, $smc, $size, $col ) = @_;
    $size ||= $self->{musicsize};
    die("Unknown glyph: $smc") unless exists $self->{musicglyphs}->{$smc};
    $self->textl( $x, $y+0.15*$self->{musicsize},
		  $self->{musicglyphs}->{$smc}, $size,
		  $self->{musicfont}, $col );
};

# Draw a line.
sub line {
    my ( $self, $x1, $y1, $x2, $y2, $col ) = @_;
    $col ||= $black;

    if ( $self->{im} ) {
	$_ = scale($_) for $x1, $x2, $y1, $y2;
	$self->{im}->line( x1 => $x1, y1 => $y1,
			   x2 => $x2, y2 => $y2,
			   color => $col );
    }
    if ( $self->{pdf} ) {
	my $gfx = $self->{page}->gfx;
	$gfx->save;
	$gfx->strokecolor($col);
	$gfx->move( $x1, PAGE_HEIGHT-$y1 );
	$gfx->linewidth(1);
	$gfx->line( $x2, PAGE_HEIGHT-$y2 );
	$gfx->stroke;
	$gfx->restore;
    }
}

my %fontcache;

# Setup fonts.
sub initfonts {
    my ( $self, $size ) = @_;
    $size ||= 20;

    # Make font objects.
    my @fonts =  qw( titlefont stitlefont textfont );
    push( @fonts, qw( chordfont chrdfont
		      musicfont muscfont markfont ) )
      unless $self->{npp};

    for ( @fonts ) {
	my $ff = $self->{fontdir} . $fonts->{$_};
	unless ( -r $ff ) {
	    my $msg = "$ff: $!\n";
	    $msg .= "(Forgot to set environment variable FONTDIR?)\n"
	      unless $ENV{FONTDIR} || $App::Packager::PACKAGED;
	    die($msg);
	}
	if ( $self->{im} ) {
	    $self->{$_} =
	      $fontcache{$ff} ||= Imager::Font->new( file => $ff )
	      or die( "$_: ", Imager->errstr );
	}
	if ( $self->{pdf} ) {
	    unless ( $fontcache{$ff} ) {
		unless ( $fontcache{$ff} ) {
		    my $f = $self->{pdf}->ttfont( $ff );
		    $fontcache{$ff} = $f;
		}
		warn( "$ff: ", $fontcache{$ff}->glyphNum, " glyphs\n" )
		  if FONTSX;
	    }
	    $self->{$_} = $fontcache{$ff};
	}
    }

    $self->{musicsize} = $size;
    $self->{chordsize} = $self->{musicsize};
    $self->{musicglyphs} = \%smufl;
    if ( $self->{npp} ) {
	$self->{titlesize} = 87;
	$self->{stitlesize} = 77;
	# Text is slightly wider??
	require Imager::Matrix2d;
	# Don't scale the titlefont as well :)
	my $ff = $self->{fontdir} . $fonts->{textfont};
	$self->{textfont} = Imager::Font->new( file => $ff);
	$self->{textfont}->transform(matrix=>Imager::Matrix2d->scale(x=>1.05,y=>1));
    }
    else {
	$self->{titlesize}  = $self->{musicsize};
	$self->{stitlesize} = 0.85 * $self->{titlesize};
    }

}

################ NPP routines ################

sub npp_chord {
    my ( $self, $x, $y, $c, $flags ) = @_;
    my ( $root, $quality, $bass ) = $self->xchord($c);

    # Flags: 0x00   normal
    #        0x01   condensed
    #        0x02   alternate
    #        0x03   condensed, alternate
    #               condensed alternate is the same as alternate

    if ( $c eq "NC" ) {
	my $img = $self->getimg("root_nc");
	$x += 29;
	$y += 41;
	if ( $flags & CHORD_CONDENSED ) {
	    $img = $img->scale( xscalefactor => 0.7, yscalefactor => 1 );
	    $x -= 31;
	}
	if ( $flags & CHORD_ALTERNATIVE ) {
	    # Need anything?
	}
	$self->{im}->rubthrough( src => $img,
				 tx => $x, ty => $y );
	return;
    }

    if ( $c =~ /^(.+)\*(.*)\*(.*)$/ ) {
	$self->textl( $x + 85, $y + 168, $2,
		      $self->{stitlesize}, $self->{stitlefont} );
	$c = $1.$3;
    }
    my $img = $self->chordimg( $c, $flags );
    if ( $flags & CHORD_ALTERNATIVE ) {
	$self->{im}->rubthrough( src => $img,
				 tx => $x + 9, ty => $y - 98 );
    }
    else {
	$self->{im}->rubthrough( src => $img, tx => $x, ty => $y );
	return;
    }

}

sub xchord {
    my ( $self, $c ) = @_;
    my ( $root, $quality, $bass ) = ( "", "", "" );
    $c = lc($c);
    return ( "nc", "", "" ) if $c eq "nc";

    if ( $c =~ m;^(.*)/(.+)$; ) {
	$c = $1;
	$bass = $2;
    }
    if ( $c =~ m;^([a-gw][b#]?)(.*)$; ) {
	$root = $1;
	$quality = $2;
	if ( $quality =~ s/^-/m/ ) {
	    $quality .= $self->{npp_minor};
	}
    }
    $quality =~ s/\#/x/g;
    $quality =~ s/\^/v/g;
    $quality =~ s/\+/p/g;
    ( $root, $quality, $bass );
}

my $im_bar;

sub npp_bar {
    my ( $self, $x, $y, $bar ) = @_;
    $bar ||= "bar";

    $im_bar ||=
      {
       barlineSingle  =>
         $self->getimg("single_barline")->scale( scalefactor => 2 ),
       barlineDouble  =>
         $self->getimg("double_barline")->scale( scalefactor => 2 ),
       barlineFinal   =>
         $self->getimg("double_barline_close")->scale( scalefactor => 2 ),
       repeatLeft     =>
         $self->getimg("repeat_barline_open"),
       repeatRight    =>
         $self->getimg("repeat_barline_close"),
      };

    $y -= 18 if $bar eq "repeatLeft" || $bar eq "repeatRight";
    $x -= 25 if $bar eq "repeatRight";
    $x -= 1 if $bar eq "repeatLeft";
    $x -= 7 if $bar eq "barlineDouble";
    $x -= 3 if $bar eq "barlineFinal";
    $x -= 9 if $bar eq "barlineSingle";
    my $w = $im_bar->{$bar}->getwidth;
    $self->{im}->rubthrough( src => $im_bar->{$bar},
			     tx => $x - $w/2, ty => $y );
}

sub npp_sig {
    my ( $self, $x, $y, $s ) = @_;
    $self->{im}->rubthrough( src => $self->getimg("time_signature_$s")
			            ->scale( xscalefactor => 0.95,
					     yscalefactor => 1.05 ),
			     tx => $x-63, ty => $y+12 );
}

sub npp_mark {
    my ( $self, $x, $y, $m ) = @_;
    $self->{im}->rubthrough( src => $self->getimg("rehearsal_mark_$m"),
			     tx => $x-55, ty => $y-76 );
}

sub npp_repeat {
    my ( $self, $x, $y, $n ) = @_;
    my $r = $self->getimg("root_" . ("x" x $n));
    my $w = $r->getwidth;
    $self->{im}->rubthrough( src => $r,
			     tx => $x - $w/2 - 8,
			     ty => $y + 56 );
}

sub npp_ending {
    my ( $self, $x, $y, $n ) = @_;
    $n = $n == 1 ? "first"
      : $n == 2 ? "second"
	: $n == 3 ? "third"
	  : "zero";
    $self->{im}->rubthrough( src => $self->getimg("ending_$n"),
			     tx => $x, ty => $y - 72 );
}

sub npp_sign {
    my ( $self, $x, $y, $sign ) = @_;
    $x -= 16 if $sign eq "fermata";
    $self->{im}->rubthrough( src => $self->getimg($sign),
			     tx => $x + 7, ty => $y - 88 );
}

sub npp_slash {
    my ( $self, $x, $y ) = @_;
    $self->{im}->rubthrough( src => $self->getimg("root_slash"),
			     tx => $x, ty => $y );
}

my %npp_imgcache;

sub getimg {
    my ( $self, $img ) = @_;
    return $npp_imgcache{$img} if $npp_imgcache{$img};

    my $if = $self->{prefab} . $img . ".png";

    if ( $self->{npp} eq "hand" ) {
	# iRealPro uses some non-hand symbols even though nice alternatives exist.
	unless ( $self->{npp_strict} && $img =~ /rehearsal_mark|root_nc|root_xx/ ) {
	    $if =~ s/\.png/_hand.png/;
	}
	unless ( -s $if ) {
	    # Fallback to non-hand symbols.
	    $if =~ s/_hand\././;
	}
    }

    my $red = 0;
    unless ( -s $if ) {
	$red = 1;
	warn("Substituting <notfound> for \"$img\"\n");
	$if = $self->{prefab} . "quality_h.png";
	$if =~ s/\.png/_hand.png/ if $self->{npp} eq "hand";
    }
    $npp_imgcache{$img} = Imager->new( file => $if )
      or die( Imager->errstr );

    # Some symbols are rendered in red.
    $red ||=  $img =~ /^ (?:
			   .*rehearsal_mark_. |
			   repeat_barline_(?:open|close) |
			   time_signature_.. |
			   ending_.* |
			   coda | fermata | segno
		       ) $/x;

    # The barline images are white instead of black. Reverse.
    $npp_imgcache{$img}->map( all => [ reverse( 0..255) ], alpha => [] )
      if $img =~ /(single|double)_barline/;

    # Colourize if necessary.
    $npp_imgcache{$img}->map( red => [ reverse( 0..255) ] ) if $red;

    return $npp_imgcache{$img};
}

sub chordimg {
    my ( $self, $chord, $flags ) = @_;
    my ( $root, $quality, $bass ) = $self->xchord($chord);

    my $img = join( "|", "", $root, $quality||"", $bass||"",
		         sprintf("%d", $flags), "" );
    return $npp_imgcache{$img} if $npp_imgcache{$img};

    my $im = Imager->new( xsize => 218,
			  ysize => 262,
			  model => 'rgba'
			) or die( Imager->errstr );

    my $acc;
    ( $root, $acc ) = ( $1, $2 ) if $root =~ /^([a-gw])([b#x])$/;
    $acc = $acc eq 'b' ? "flat" : "sharp" if $acc;

    my $dx = $flags & CHORD_ALTERNATIVE ? 6 : 0;
    my $dy = $flags & CHORD_ALTERNATIVE ? -6 : 0;
    $im->rubthrough( src => $self->getimg("root_$root"),
		     tx => 0, ty => 0 );
    $im->rubthrough( src => $self->getimg("root_$acc"),
		     tx => 0, ty => 0 ) if $acc;
    $im->rubthrough( src => $self->getimg("quality_$quality"),
		     tx => 84, ty => $dy+80 ) if $quality;

    if ( $bass ) {

	( $root, $acc ) = $bass =~ /^([a-g])([b#x]?)$/;
	$acc = $acc eq 'b' ? "flat" : "sharp" if $acc;

	$dx = $flags & CHORD_CONDENSED ? 10 : 0;
	$dx += 50 if $flags & CHORD_ALTERNATIVE;
	$dy = $flags & CHORD_CONDENSED ? -5 : 0;
	$dy -= 5 if $flags & CHORD_ALTERNATIVE;
	my $sc = $flags & CHORD_CONDENSED ? 0.68 : 0.65;
	my $sc2 = $flags & CHORD_CONDENSED ? 0.58 : 0.55;
	$im->rubthrough( src => $self->getimg("root_$root")
			 ->scale( scalefactor => $sc ),
			 tx => $dx+65, ty => $dy+153 );
	$im->rubthrough( src => $self->getimg("root_$acc")
			 ->scale( scalefactor => $sc ),
			 tx => $dx+65, ty => $dy+177 ) if $acc;
	$im->rubthrough( src => $self->getimg("root_slash")
			 ->scale( xscalefactor => 0.85,
				  yscalefactor => $sc2 ),
			 tx => $dx+0, ty => 142 );
    }

    $im = $im->scale( xscalefactor => 0.7, yscalefactor => 1 ) if $flags & CHORD_CONDENSED;
    $im = $im->scale( xscalefactor => 0.62, yscalefactor => 0.62 ) if $flags & CHORD_ALTERNATIVE;

    return $npp_imgcache{$img} = $im;
}

1;

=begin experimental

for ( "mpdfx.pl", "mpng.pl" ) {
    open( my $fd, "<", $_ );
    my $data = do { local $/; <$fd> };
    eval $data or die($@);
}

=end experimental

=cut

1;
