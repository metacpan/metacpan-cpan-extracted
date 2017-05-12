#! perl

use strict;
use warnings;
use Carp;

package Data::iRealPro::Song;

our $VERSION = "1.02";

use Encode qw( encode_utf8 );

sub new {
    my ( $pkg, %args ) = @_;
    my $self = bless { %args }, $pkg;
    $self->parse( $args{data} ) if $args{data};
    return $self;
}

sub actual_key {
    my ( $self, $n ) = @_;
    # Actual key as shown. Fixed range, only flats, no minor.
    my $keys = [ qw( C Db D Eb E F Gb G Ab A Bb B ) ];
    wantarray && !defined($n) && return @$keys;
    $keys->[$n % 12];
}

sub parse {
    my ( $self, $data ) = @_;

    # Split song data into components.
    my @a = split( '=', $data );
    unless ( @a == ( $self->{variant} eq "irealpro" ? 10 : 6 ) ) {
	Carp::croak( "Incorrect ", $self->{variant}, " format 1 " . scalar(@a) );
    }

    my $tokstring;

    if ( $self->{variant} eq "irealpro" ) {
	$self->{title}		 = shift(@a);
	$self->{composer}	 = shift(@a);
	$self->{a2}		 = shift(@a); # ??
	$self->{style}		 = shift(@a);
	$self->{key}		 = shift(@a); # C ...
	$self->{actual_key}	 = shift(@a); # 0 ...
	$self->{raw}		 = shift(@a);
	$self->{actual_style}	 = shift(@a);
	$self->{actual_tempo}	 = shift(@a);
	$self->{actual_repeats}	 = shift(@a);
    }
    elsif ( $self->{variant} eq "irealbook" ) {
	$self->{title}	         = shift(@a);
	$self->{composer}        = shift(@a);
	$self->{style}	         = shift(@a);
	$self->{a3}	         = shift(@a); # ??
	$self->{key}	         = shift(@a);
	$self->{raw}	         = shift(@a);
	# Sometimes key and a3 seem swapped.
	$self->{key} = $self->{a3}, $self->{a3} = "n" if $self->{key} eq "n";
    }
    $tokstring = $self->{raw};

    # iRealPro format must start with "1r34LbKcu7" magic.
    unless ( !!($self->{variant} eq "irealpro")
	     ==
	     !!($tokstring =~ /^1r34LbKcu7/) ) {
	Carp::croak( "Incorrect ", $self->{variant},
		     " format 2 " . substr($tokstring,0,20) );
    }

    # If iRealPro, deobfuscate. This will also get rid of the magic.
    if ( $self->{variant} eq "irealpro" ) {
	$tokstring = deobfuscate($tokstring);
	warn( "TOKSTR: >>", $tokstring, "<<\n" ) if $self->{debug};
    }

    # FROM HERE we have a pure data string, independent of the
    # original data format.

    $self->{data} = $tokstring;
    delete $self->{raw} unless $self->{debug};

    return $self;
}

sub tokens {
    my ( $self ) = @_;
    $self->tokenize unless $self->{tokens};
    return $self->{tokens};
}

sub cells {
    my ( $self ) = @_;
    $self->make_cells unless $self->{cells};
    return $self->{cells};
}

################ Tokenizer ################

#### Chord qualities.
#
# key is the official way to write a chord quality. This is what the iRealPro
#     editor produces when you specify chords via the menus.
# value is the quality as used to select the corresponding image files.
#
# Often used variants are v for ^, x for # and h for ø.
#
# Anything else should be written as a *...* quality.

my %chordqual =
  (  ""			=> '',
     "+"		=> 'p',
     "-"		=> 'm',
     "-#5"		=> 'mx5',
     "-11"		=> 'm11',
     "-6"		=> 'm6',
     "-69"		=> 'm69',
     "-7"		=> 'm7',
     "-7b5"		=> 'm7b5',
     "-9"		=> 'm9',
     "-^7"		=> 'mv7',
     "-^9"		=> 'mv9',
     "-b6"		=> 'mb6',
     "11"		=> '11',
     "13"		=> '13',
     "13#11"		=> '13x11',
     "13#9"		=> '13x9',
     "13b9"		=> '13b9',
     "13sus"		=> '13sus',
     "2"		=> '2',
     "5"		=> '5',
     "6"		=> '6',
     "69"		=> '69',
     "7"		=> '7',
     "7#11"		=> '7x11',
     "7#5"		=> '7x5',
     "7#9"		=> '7x9',
     "7#9#11"		=> '7x9x11',
     "7#9#5"		=> '7x9x5',
     "7#9b5"		=> '7x9b5',
     "7alt"		=> '7alt',
     "7b13"		=> '7b13',
     "7b13sus"		=> '7b13sus',
     "7b5"		=> '7b5',
     "7b9"		=> '7b9',
     "7b9#11"		=> '7b9x11',
     "7b9#5"		=> '7b9x5',
     "7b9#9"		=> '7b9x9',
     "7b9b13"		=> '7b9b13',
     "7b9b5"		=> '7b9b5',
     "7b9sus"		=> '7b9sus',
     "7sus"		=> '7sus',
     "7susadd3"		=> '7susadd3',
     "9"		=> '9',
     "9#11"		=> '9x11',
     "9#5"		=> '9x5',
     "9b5"		=> '9b5',
     "9sus"		=> '9sus',
     "^"		=> 'v',
     "^13"		=> 'v13',
     "^7"		=> 'v7',
     "^7#11"		=> 'v7x11',
     "^7#5"		=> 'v7x5',
     "^9"		=> 'v9',
     "^9#11"		=> 'v9x11',
     "add9"		=> 'add9',
     "alt"		=> '7alt',
     "h"		=> 'h',
     "h7"		=> 'h7',
     "h9"		=> 'h9',
     "o"		=> 'o',
     "o7"		=> 'o7',
     "sus"		=> 'sus',
  );

# Build regex.
my $p_root  = qr{ (?: [ABCDEFG][#b]? | W) }x;
# By using reverse the longest alternatives will be tested first.
my $p_qual = join("|", map { quotemeta } reverse sort keys %chordqual);
$p_qual = qr{ (?: \*[^*]*\* | $p_qual ) }xo;
my $p_chord = qr{ $p_root $p_qual (?: / $p_root )? }xo;

sub tokenize {
    my ( $self ) = @_;

    $_ = $self->{data};

    # Make tokens.
    my @d;
    my $l0 = length($_);
    my $index = 0;

    my $d = sub {
	push( @d, [ $_[0], $_[1] // ${^MATCH}, $index ] );
	printf STDERR ("%3d  %-8s %s\n", $index, $_[1] // ${^MATCH}, $_[0] )
	  if $self->{debug};
    };

    # IMPORTANT: iReal design is visually oriented. All info is added
    # to the current cell until the pointer advances to the next cell.

    # Mark markup spaces.
    s/([\}\]])( +)([\[\]\{\|])/$1 . ( "\240" x length($2) ) . $3/ge;

    while ( length($_) ) {
	if ( /^\{/p ) {		# |:
	    $d->( "start repeat" );
	}
	elsif ( /^\}/p ) {	# :|
	    $d->( "end repeat" );
	}
	elsif ( /^\[/p ) {	# start section
	    $d->( "start section" );
	}
	elsif ( /^\]/p ) {	# end section
	    $d->( "end section" );
	}
	elsif ( /^\*([ABCDvi])/p ) { # section mark
	    $d->( "mark $1" );
	}
	elsif ( /^T(\d)(\d)/p ) { # time signature
	    $d->( "time " . _timesig( $1, $2) );
	}
	elsif ( /^([sl])/p ) {	# small/large indicator for chords
	    $d->( $1 eq "s" ? "small" : "large" );
	}
	elsif ( /^$p_chord(?:\($p_chord\))?/p ) {
	    my $t = ${^MATCH};
	    if ( $t =~ /^(.+)Z$/ ) {
		$d->( "chord " . $self->xpose($1) );
		$d->( "end" );
	    }
	    else {
		$d->( "chord " . $self->xpose($t) );
	    }
	}
	elsif ( /^$p_root/p ) {
	    warn( "Unparsable chord: " . ${^MATCH} . "\n" );
	    $d->( "chord? " . $self->xpose(${^MATCH}) );
	}
	elsif ( /^\($p_chord\)/p ) {
	    $d->( "chord " . $self->xpose(${^MATCH}) );
	}
	elsif ( /^n/p ) {	# silent chord
	    $d->( "chord NC" );
	}
	elsif ( /^x/p ) {	# repeat the previous measure
	    $d->( "measure repeat single" );
	}
	elsif ( /^r/p ) {	# repeat the previous two measures
	    $d->( "measure repeat double" );
	}
	elsif ( /^ +/p ) {	# advance to next cell
	    $d->( "advance " . length(${^MATCH}), " " );
	}
	elsif ( /^\|/p ) {	# bar
	    $d->( "bar" );
	}
	elsif ( /^N(\d)/p ) {
	    $d->( "alternative $1" );
	}
	elsif ( /^,/p ) {	# token separator
	}
	elsif ( /^Z/p ) {	# end of song or major section
	    $d->( "end" );
	}
	elsif ( /^U/p ) {	# end repetition
	    $d->( "stop" );
	}
	elsif ( /^p/p ) {
	    $d->( "slash repeat" );
	}
	elsif ( /^Q/p ) {	# 1: jump to coda; 2: coda location
	    $d->( "coda" );
	}
	elsif ( /^f/p ) {	# fermata; precedes the chord
	    $d->( "fermata" );
	}
	elsif ( /^S/p ) {	# segno
	    $d->( "segno" );
	}
	elsif ( /^Y/p ) {	# add vertical space
	    $d->( "vspace" );
	}
	elsif ( /^\240+/p ) {	# markup space
	    $d->( "hspace " . length(${^MATCH}), " " );
	}
	elsif ( /^\<(?:\*(\d\d))?(.*?)\>/ps ) { # text
	    my $t = $2;
	    $t =~ s/\s+$//;
	    $d->( "text " . ( $1 || 0 ) . " " . $t );
	}
	elsif ( /^([\r\n]+)/p ) {
	    # Silently ignore newlines.
	}
	elsif ( /^(.)/ps ) {
	    $d->( "ignore $1" );
	    warn( "Unhandled token: " . ${^MATCH} . "\n" );
	}
	$_ = ${^POSTMATCH};
	$index = $l0 - length($_);
    }

    $self->{tokens} = [ map { $_->[0] } @d ];
    $self->{raw_tokens} = [ @d ] if $self->{raw}; # USED?

    return $self->{tokens};
}

sub chordqual { \%chordqual }

use Data::Struct;

my @fields = qw( flags vs sz chord subchord text mark sign time lbar rbar alt );
struct Cell => @fields;

sub make_cells {
    my ( $self ) = @_;

    my $tokens = $self->tokens;
    my $cells = [];
    my $cell;
    my $chordsize = 0;		# normal
    my $vspace = 0;		# normal

    my $new_cell = sub {
	$cell = struct "Cell";
	$cell->sz = $chordsize if $chordsize;
	$cell->vs = $vspace;	# always
	push( @$cells, $cell );
    };

    my $new_measure = sub {
	# This is to make sure a bar on the beginning of a line has a
	# corresponding bar on the end of the previous line.
	# However, we cannot do that if there's a vertical shift
	# involved.
	if ( @$cells >= 2
	     &&
	     $cells->[-2]->vs == $cells->[-1]->vs
	   ) {
	    $cells->[-2]->rbar ||= "barlineSingle";
	}
	$cells->[-1]->lbar ||= "barlineSingle";
    };

    $new_cell->();		# TODO section? measure?

    foreach my $t ( @$tokens ) {

	if ( $t eq "start section" ) {
	    $cell->lbar = "barlineDouble";
	    next;
	}

	if ( $t eq "start repeat" ) {
	    $cell->lbar = "repeatLeft";
	    next;
	}

	if ( $t eq "end repeat" ) {
	    $cells->[-2]->rbar = "repeatRight"
	      if @$cells >= 2;
	    next;
	}

	if ( $t =~ /time (\d+)\/(\d+)/ ) {
	    $cell->time = [ $1, $2 ];
	    next;
	}

	if ( $t =~ /^hspace\s+(\d+)$/ ) {
	    $new_cell->() for 1..$1;
	    next;
	}

	# |Bh7 E7b9 ZY|QA- |
	if ( $t eq "vspace" ) {
	    $vspace++;
	    $cells->[-1]->vs = $vspace
	      if @$cells >= 1;
	    next;
	}

	if ( $t eq "end" ) {
	    $cells->[-2]->rbar = "barlineFinal"
	      if @$cells >= 2;
	    next;
	}

	if ( $t eq "end section" ) {
	    $cells->[-2]->rbar = "barlineDouble"
	      if @$cells >= 2;
	    next;
	}

	if ( $t eq "bar" ) {
	    $new_measure->();
	    next;
	}

	if ( $t =~ /^(segno|coda|fermata)$/ ) {
	    $cell->sign = $1;
	    next;
	}

	if ( $t =~ /^chord\s+(.*)$/ ) {
	    my $c = $1;

	    if ( $c =~ s/\((.+)\)// ) {
		if ( $c ) {
		    $cell->subchord = $1;
		}
		else {
		    $cells->[-2]->subchord = $1
		      if @$cells >= 2;
		    next;
		}
	    }

	    $cell->chord = $c;
	    $new_cell->();
	    next;
	}

	if ( $t =~ /^alternative\s+(\d)$/ ) {
	    $cell->alt = $1;
	}

	if ( $t eq "small" ) {
	    $cell->sz = $chordsize = 1;
	    next;
	}

	if ( $t eq "large" ) {
	    $cell->sz = $chordsize = 0;
	    next;
	}

	if ( $t =~ /^mark (.)/ ) {
	    $cell->mark = $1;
	    next;
	}

	if ( $t eq "stop" ) {
	    $cell->flags = 0x01 | ($cell->flags||0); # WIP
	    next;
	}

	if ( $t =~ /^text\s+(\d+)\s(.*)/ ) {
	    $cell->text =  [ $1, $2 ];
	    next;
	}

	if ( $t =~ /^advance\s+(\d+)$/ ) {
	    $new_cell->() for 1..$1;
	    next;
	}

	if ( $t =~ /^measure repeat (single|double)$/ ) {
	    my $c = $1 eq "single" ? "repeat1Bar" : "repeat2Bars";
	    $cell->chord = $c;
	    $new_cell->();
	    next;
	}

	if ( $t =~ /^slash repeat$/ ) {
	    $cell->chord = "repeatSlash";
	    $new_cell->();
	    next;
	}

	next;

    }
    return $self->{cells} = $cells;
}

################ Transposition ################

my $notesS  = [ split( ' ', "A A# B C C# D D# E F F# G G#" ) ];
my $notesF  = [ split( ' ', "A Bb B C Db D Eb E F Gb G Ab" ) ];
my %notes = ( A => 1, B => 3, C => 4, D => 6, E => 8, F => 9, G => 11 );

sub xpose {
    my ( $self, $c ) = @_;
    return $c unless $self->{transpose};

    return $c unless $c =~ m/
				^ (
				    [CF](?:\#)? |
				    [DG](?:\#|b)? |
				    A(?:\#|b)? |
				    E(?:b)? |
				    B(?:b)?
				  )
				  (.*)
			    /x;
    my ( $r, $rest ) = ( $1, $2 );
    my $mod = 0;
    $mod-- if $r =~ s/b$//;
    $mod++ if $r =~ s/\#$//;
    warn("WRONG NOTE: '$c' '$r' '$rest'") unless $r = $notes{$r};
    $r = ($r - 1 + $mod + $self->{transpose}) % 12;
    return ( $self->{transpose} > 0 ? $notesS : $notesF )->[$r] . $rest;
}

my $_sigs;

sub _timesig {
    my ( $time_d, $time_n ) = @_;
    $_sigs ||= { "22" => "2/2",
		 "32" => "3/2",
		 "24" => "2/4",
		 "34" => "3/4",
		 "44" => "4/4",
		 "54" => "5/4",
		 "64" => "6/4",
		 "74" => "7/4",
		 "28" => "2/8",
		 "38" => "3/8",
		 "48" => "4/8",
		 "58" => "5/8",
		 "68" => "6/8",
		 "78" => "7/8",
		 "98" => "9/8",
		 "12" => "12/8",
	       };

    $_sigs->{ "$time_d$time_n" }
      || Carp::croak("Invalid time signature: $time_d/$time_n");
}

################ Exports ################

sub as_string {
    my ( $self ) = @_;

    join( "=",
	  $self->{title},
	  $self->{composer},
	  $self->{a2}                 || '',
	  $self->{style},
	  $self->{key},
	  $self->{actual_key}         || '',
	  obfuscate( $self->{data} ),
	  $self->{actual_style}       || '',
	  $self->{actual_tempo}       || 0,
	  $self->{actual_repeats}     || 0,
	);
}

sub export {
    my ( $self, %args ) = @_;
    Carp::carp(__PACKAGE__."::export is deprecated, please use 'as_string' instead");

    my $v = $args{variant} || $self->{variant} || "irealpro";
    my $r;

    if ( $v eq "irealbook" ) {
	$r = join( "=",
		   $self->{title},
		   $self->{composer},
		   $self->{style},
		   $self->{key},
		   $self->{a3} || '',
		   $self->{data},
		 );
    }
    else {
	$r = $self->as_string;
    }
    if ( $args{html} || $args{uriencode} || !defined( $args{uriencode} ) ) {
	$r = encode_utf8($r);
	$r =~ s/([^-_.A-Z0-9a-z*\/\'])/sprintf("%%%02X", ord($1))/ge;
    }
    return $r;
}

# Obfuscate...
# IN:  [T44C   |G   |C   |G   Z
# OUT: 1r34LbKcu7[T44CXyQ|GXyQ|CXyQ|GXyQZ
sub obfuscate {
    my ( $t ) = @_;die unless defined $t;
    for ( $t ) {
	s/   /XyQ/g;		# obfuscating substitution
	s/ \|/LZ/g;		# obfuscating substitution
	s/\| x/Kcl/g;		# obfuscating substitution
	$_ = hussle($_);	# hussle
	s/^/1r34LbKcu7/;	# add magix prefix
    }
    $t;
}

# Deobfuscate...
# IN:  1r34LbKcu7[T44CXyQ|GXyQ|CXyQ|GXyQZ
# OUT: [T44C   |G   |C   |G   Z
sub deobfuscate {
    my ( $t ) = @_;
    for ( $t ) {
	s/^1r34LbKcu7//;	# remove magix prefix
	$_ = hussle($_);	# hussle
	s/XyQ/   /g;		# obfuscating substitution
	s/LZ/ |/g;		# obfuscating substitution
	s/Kcl/| x/g;		# obfuscating substitution
    }
    $t;
}

# Symmetric husseling.
sub hussle {
    my ( $string ) = @_;
    my $result = '';

    while ( length($string) > 50 ) {

	# Treat 50-byte segments.
	my $segment = substr( $string, 0, 50, '' );
	if ( length($string) < 2 ) {
	    $result .= $segment;
	    next;
	}

	# Obfuscate a 50-byte segment.
	$result .= reverse( substr( $segment, 45,  5 ) ) .
		   substr( $segment,  5, 5 ) .
		   reverse( substr( $segment, 26, 14 ) ) .
		   substr( $segment, 24, 2 ) .
		   reverse( substr( $segment, 10, 14 ) ) .
		   substr( $segment, 40, 5 ) .
		   reverse( substr( $segment,  0,  5 ) );
    }

    return $result . $string;
}

1;
