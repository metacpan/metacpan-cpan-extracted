#!/usr/bin/perl

package App::Music::PlayTab;

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec  5 13:04:32 2017
# Update Count    : 568
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

use App::Music::PlayTab::Version;
our $VERSION = $App::Music::PlayTab::Version::VERSION;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = ( 'playtab', $VERSION );

use base qw(Exporter);
our @EXPORT = qw(run);

################ Command line parameters ################

use Getopt::Long;
sub app_options();

my $output;
my $generate;
my $preamble;
my $gxpose = 0;			# global xpose value
my $verbose = 0;		# verbose processing
my $lilypond = 0;		# use LilyPond syntax
my $bpm = 4;
my $syntax;			 # show syntax help

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test

################ The Process ################

my $line;			# current line (for messages)

my $xpose = $gxpose;

my $data;			# opus being constructed
my $entry;			# entry under construction
my $width  = 30;		# horizontal 'step' for chords
my $height = -15;		# vertical 'step' for lines
my $margin = 40;		# default indentation, if required
my $indent = 0;			# actual indentation
my $barno;			# barnumber (slightly magical)
my $s_margin = $margin;		# save values
my $s_indent = 0;		# save values

use App::Music::PlayTab::Output;

use Encode;
use Clone qw(clone);

sub run {
    local (@ARGV) = @_ ? @_ : @ARGV;

    app_options();
    binmode( STDERR, ':utf8' );
    print STDOUT ("ok 1\n") if $test;

    if ( defined $output ) {
	open(OUTPUT, ">$output") or print STDOUT ("not ") if $test;
	print STDOUT ("ok 2\n") if $test;
    }
    else {
	die("Test mode requires -output option to be set\n") if $test;
	*OUTPUT = *STDOUT;
    }

    # Options post-processing.
    $trace |= ($debug || $test);
    $xpose = $gxpose;

    # Actually we should probe all backends and let them register what
    # they can handle.
    $generate = 'PDF' if $Cava::Packager::PACKAGED;
    if ( $generate ) {
	if ( $generate eq 'ps' ) {
	    $generate = 'PostScript';
	}
	elsif ( $generate eq 'pdf' ) {
	    $generate = 'PDF';
	}
    }
    elsif ( $output ) {
	if ( $output =~ /\.ps$/i ) {
	    $generate = 'PostScript';
	}
	elsif ( $output =~ /\.pdf$/i ) {
	    $generate = 'PDF';
	}
	elsif ( $output =~ /\.dmp$/i ) {
	    $generate = 'Dump';
	}
    }

    $generate ||= 'PDF';

    my $gen = App::Music::PlayTab::Output->new({
		      generate => $generate,
		      output => $output,
	        });

    print STDOUT ("ok 3\n") if $test;

    reset_globals();

    while ( <> ) {
	# Skip comment lines.
	next if /^\s*#/;
	# Skip LilyPond comment lines.
	next if $lilypond && /^\s*%/;
	# Remove LilyPond line number comments.
	$lilypond && s/\s+\%\s*\d+.*//;
	# Skip empty lines.
	next unless /\S/;

	$_ = decode_utf8($_);
	chomp($line = $_);

	s/\^\s+//;
	if ( /^!\s*(.*)/ ) {
	    control($1);
	    next;
	}

	if ( /^\s*\[/ ) {
	    # Chord diagram(s).
	    while ( /^\s*\[([^]]+)\](.*)/ ) {
		eval { chord($1) };
		errout($@) if $@;
		$_ = $2;
	    }
	    next;
	}

	if ( /^\s*\|/ ) {
	    bar($_);
	    next;
	}

	# Spacing/margin notes.

	if ( /^%?[-+=<]/ && $entry->{prefix} && $entry->{prefix} ne "" ) {
	    $entry->{height} = $height;
	    $entry->{margin} = 0;
	    $entry->{measures} = [];
	    push_entry();
	}

	if ( /^%?=(.*)/ ) {
	    $entry->{prefix} = $1;
	    $entry->{pfx_vsp} = 2;
	    next;
	}
	if ( /^%?-(.*)/ ) {
	    $entry->{prefix} = $1;
	    $entry->{pfx_vsp} = 1;
	    next;
	}
	if ( /^%?\+(.*)/ ) {
	    $entry->{prefix} = $1;
	    $entry->{pfx_vsp} = 0;
	    next;
	}
	if ( /^%?\</ ) {	# cancel margin changes
	    $s_margin = $margin;
	    $s_indent = $indent;
	    $margin = $indent = 0;
	    next;
	}

	# Text. Treat as +Prefix without measures.
	if ( $entry->{prefix} && $entry->{prefix} ne "" ) {
	    $entry->{height} = $height;
	    $entry->{margin} = 0;
	    $entry->{measures} = [];
	    push_entry();
	}
	text($line);
    }
    continue {
	if ( eof ) {
	    $gen->generate({ opus => $data });
	    reset_globals();
	}
    }

    print STDOUT ("ok 4\n") if $test;

    print STDOUT ("ok 5\n") if $test;

    close OUTPUT if defined $output;
    exit 0 unless $test;
}

sub push_entry {
    return unless $entry && keys(%$entry);
    push( @{ $data->{lines} }, $entry );
    $entry = {};
}

sub reset_globals {
    $data = {};
    $entry = {};
    $width  = 30;		# horizontal 'step' for chords
    $height = -15;		# vertical 'step' for lines
    $margin = 40;		# default indentation, if required
    $indent = 0;		# actual indentation
    undef $barno;		# barnumber (slightly magical)
    $s_margin = $margin;	# save values
    $s_indent = 0;		# save values
}

################ Subroutines ################

sub bar {
    my ($line) = @_;

    my @m = ();
    $indent = $margin if $entry->{prefix} && $entry->{prefix} ne "";
    $entry->{barno}  = $barno if defined $barno && $barno > 0;
    $entry->{width}  = $width;
    $entry->{height} = $height;
    $entry->{margin} = $indent if $indent;
    $entry->{bpm}    = $bpm;

    # Autosensing...
    # Uppercase chords -> not lilypond mode.
    if ( $line =~ /^\s*\|\s*[A-G]/ ) {
	$lilypond = 0;
    }
    # Lowcase chords and : modifiers -> lilypond mode.
    elsif ( $line =~ /^\s*\|\s*[a-g].*?:(m|\d|sus|aug|dim)/ ) {
	$lilypond = 1;
    };


    if ( $lilypond ) {
	# LilyPond chords use : and ., so don't split on these.
	$line =~ s/([|`'])/ $1 /g;	#'`])/;
    }
    else {
	$line =~ s/([|.:`'])/ $1 /g;	#'`])/;
    }
    $line =~ s/  +/ /g;

    my (@c) = split(' ', $line);
    my $firstbar = 1;

    while ( @c > 0 ) {
	eval {
	    my $c = shift(@c);
	    if ( $c eq '|' ) {
		if ( $firstbar ) {
		    $firstbar = 0;
		}
		else {
		    push( @{ $entry->{measures} }, [ @m ] );
		    $barno++ if defined $barno;
		}
		@m = ();
	    }
	    elsif ( $c eq ':' ) {
		push( @m, "again" );
	    }
	    elsif ( $c eq '.' ) {
		push( @m, "space" );
	    }
	    elsif ( $c eq '%' ) {
		my $xs = 1;
		if ( $lilypond ) {
		    $xs = $bpm;
		}
		else {
		    while ( @c > 0 && $c[0] eq '.' ) {
			shift(@c);
			$xs++;
		    }
		}
		push( @m, [ "same", 1, $xs ] );
	    }
	    elsif ( $c eq '-' ) {
		push( @m, "rest" );
	    }
	    elsif ( $c eq '\'' ) {
		push( @m, "hmore" );
	    }
	    elsif ( $c eq '`' ) {
		push( @m, "hless" );
	    }
	    else {
		my $chord = parse_chord($c);

		if ( $chord->is_rest ) {
		    push( @m, "rest" );
		}
		else {
		    $chord->transpose($xpose) if $xpose;
		    push( @m, clone($chord) );
		}
		if ( my $d = $chord->duration ) {
		    $d = int($d / ($chord->duration_base / $bpm));
		    unshift(@c, ('.') x ($d-1)) if $d > 1;
		}
	    }
	};
	die($@) if $@ =~ /can\'t locate/i;
	errout($@) if $@;
    }

    push_entry();
}

sub control {
    local ($_) = @_;

    # Title.
    if ( /^t(?:itle)?\s+(.*)/i ) {
	$data->{title} = $1;
	return;
    }

    # Subtitle(s).
    if ( /^s(?:ub(?:title)?)?\s+(.*)/i ) {
	push( @{ $data->{subtitle} }, $1 );
	return;
    }

    # Width adjustment.
    if ( /^w(idth)?\s+([-+]?\d+)/i ) {
	set_width($2);
	return;
    }

    # Height adjustment.
    if ( /^h(eight)?\s+([-+]?\d+)/i ) {
	set_height($2);
	return;
    }

    # Margin width adjustment.
    if ( /^m(argin)?\s+([-+]?\d+)/i ) {
	set_margin($2);
	$indent = $margin if $indent;
	return;
    }
    if ( /^m(argin)?/i ) {
	$margin = $s_margin;
	$indent = $s_indent;
	return;
    }

    # Transpose.
    if ( /^x(pose)?\s+([-+])(\d+)/i ) {
	$xpose += $2.$3;
	return;
    }

    # Bar numbering.
    if ( /^n(umber)?\s+([-+]?\d+)?/i ) {
	set_barno(defined $2 ? $2 ? $2 < 0 ? $2+1 : $2 : 0 : 1);
	return;
    }

    # LilyPond syntax.
    if ( /^l(?:y|ilypond)?(?:\s+(\d+))?/i ) {
	$lilypond = defined $1 ? $1 : 1;
	$bpm = ($lilypond && defined $1) ? $1 : 4;
	return;
    }

    # Global settings for drivers and so on.
    if ( /^g(?:lobal)?\s+(.*)/ ) {
	use Text::ParseWords;
	push( @{ $data->{globalsettings} }, shellwords($1) );
	return;
    }

    # Postfix text.
    if ( /^\>\s+(.+)/i ) {
	$entry->{postfix} = $1;
	return;
    }

    errout("Unrecognized control");
}

my $chordparser;
my $lilyparser;
sub parse_chord {
    my $chord = shift;

    my $parser;
    if ( $lilypond ) {
	unless ( $lilyparser ) {
	    require App::Music::PlayTab::LyChord;
	    $lilyparser = App::Music::PlayTab::LyChord->new;
	}
	$parser = $lilyparser;
    }
    else {
	unless ( $chordparser ) {
	    require App::Music::PlayTab::Chord;
	    $chordparser = App::Music::PlayTab::Chord->new;
	}
	$parser = $chordparser;
    }
    $parser->parse($chord);
}

sub chord {
    my (@l) = split( ' ', $_[0] );

    die("Illegal [chord] spec, need 7 or 8 values")
	unless @l == 8 || @l == 7;

    my $cn = shift(@l);
    my $chord = eval { parse_chord($cn) };

    my @c = ();
    my $c = 0;
    foreach ( @l ) {
	$_ = -1 if lc($_) eq "x";
	if ( /^@(\d+)/ ) {
	    $c = 0+$1 if $1 > 1;
	    next;
	}
	die("Illegal [chord] spec, need 6 numbers")
	    unless /^-?\d$/ || @c == 6;
	push(@c, 0+$_);
    }

    unshift( @c, $c );
    unshift( @c, $chord ? clone($chord) : $cn );

    if ( $data->{lines}->[-1]->{chords} ) {
	push( @{ $data->{lines}->[-1]->{chords} }, \@c  );
    }
    else {
	$entry->{margin} = $margin;
	$entry->{height} = $height;
	$entry->{chords} = [ \@c ];
	push_entry();
    }
}

sub text {
    my ($line) = @_;
    $entry->{height} = $height;
    $entry->{margin} = 0;
    $entry->{prefix} = $line;
    $entry->{pfx_vsp} = 0;
    push_entry();
}

sub errout {
    my $msg = "@_";
    $msg =~ s/ at .*line \d+.*//s;
    warn("$msg\n", "Line $.: $line\n");
}

################ Helper Routines ################

sub _set_incr {
    my $var = shift;
    my $ref = shift;
    my $v = shift;
    warn("set_$var: number or increment expected\n")
      unless $v =~ /^([-+])?(\d+)$/;
    if ( defined($1) ) {
	$$ref += $1.$2;
    }
    else {
	$$ref = $2;
    }
    $entry->{$var} = $$ref if $var;
}

sub set_width  { unshift( @_, "width",     \$width  ); goto &_set_incr }

sub set_height {
    unshift( @_, "height",    \$height );
    $height = -$height;
    &_set_incr;
    $height = -$height;
}

sub set_margin { unshift( @_, "margin",    \$margin ); goto &_set_incr }
sub set_barno  {
    # Values: 0 = disable, >0 = use, <0 lead-in.
    unshift( @_, undef, \$barno );
    &_set_incr;
    $barno = undef unless $barno;
}

################ Command Line Options ################

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions('output=s'	=> \$output,
		     'generate=s' => \$generate,
		     'preamble=s' => \$preamble,
		     'transpose|x=i' => \$gxpose,
		     'lilypond=i' => \$lilypond,
		     'syntax'	=> \$syntax,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help'	=> \$help,
		     'test'	=> \$test,
		     'debug'	=> \$debug,
		    )
	 or abs($gxpose) > 11 )
    {
	app_usage(2);
    }
    app_ident if $ident;
    if ( $help ) {
	app_usage(0);
	exit(0);
    }
    if ( $syntax ) {
	$lilypond ? ly_syntax() : syntax();
	pr_syntax();
	exit(0);
    }
    $bpm = $lilypond if $lilypond;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --output XXX	output file name
    --transpose +/-N    transpose all
    --lilypond N	use LilyPond chord syntax, N = bpm
    --help		this message
    --syntax		explain chord syntax
    --ident		show identification
    --verbose		verbose information
EndOfUsage
    exit $exit if $exit != 0;
}

sub syntax {
    print STDERR <<EOD;
Notes: C, D, E, F, G, A, B.
Raised with '#' or suffix 'is', e.g. A#, Ais.
Lowered with 'b' or suffix 's' or 'es', e.g. Bes, As, Eb.

Chords: note + optional modifiers.
Chord modifiers Meaning                 [examples]
--------------------------------------------------------------
nothing         major triad             [C]
- or min or m   minor triad             [Cm Fmin Gb-]
+ or aug        augmented triad         [Caug B+]
o or 0 or dim   diminished triad        [Co D0 Fdim]
--------------------------------------------------------------
maj7            major 7th chord         [Cmaj7]
%               half-diminished 7 chord [C%]
6,7,9,11,13     chord additions         [C69]
sus sus4, sus2  suspended 4th, 2nd      [Csus]
--------------------------------------------------------------
#               raise the pitch of the note to a sharp [C11#9]
b               lower the pitch of the note to a flat [C11b9]
--------------------------------------------------------------
no              substract a note from a chord [C9no11]
--------------------------------------------------------------
() and _ may be used to avoid ambiguity, e.g. C(#9) <-> C#9 <-> C#_9

Other:          Meaning
--------------------------------------------------------------
.               Chord space
-               Rest
:               Repeats previous chord
%               Repeat pattern
/               Powerchord constructor   [D/G D/E-]
--------------------------------------------------------------
EOD
}

sub ly_syntax {
    print STDERR <<EOD;
Notes: c, d, e, f, g, a, b.
Raised with suffix 'is', e.g. ais.
Lowered with suffix 'es', e.g. bes, ees.

Chords: note + optional duration + optional modifiers.

Duration = 1, 2, 4, 8, with possible dots, e.g., "2.".
No duration means: use the duration of the previous chord.

Modifiers are preceeded with a ":".

Modifiers       Meaning                 [examples]
--------------------------------------------------------------
nothing         major triad             c4
m               minor triad             c4:m
aug             augmented triad         c4:aug
dim             diminished triad        c4:dim
--------------------------------------------------------------
maj             major 7th chord         c4:maj
6,7,9,11,13     chord additions         c4:7  c4:6.9 (dot required)
sus sus4, sus2  suspended 4th, 2nd      c4:sus
--------------------------------------------------------------
+               raise the pitch of an added note   c4:11.9+
-               lower the pitch of an added note   c4:11.9-
--------------------------------------------------------------
^               substract a note from a chord      c4:9.^11
--------------------------------------------------------------

Other:          Meaning
--------------------------------------------------------------
r               Rest                    r2
s               Rest                    s4
/               Powerchord constructor  d/g   d/e:m
--------------------------------------------------------------
EOD
}

sub pr_syntax {
    print STDERR <<EOD;
EOD
}

################ Resources ################

sub ::findlib {
    my ( $file ) = @_;

    # Packaged.
    if ( $App::Packager::PACKAGED ) {
	my $found = App::Packager::GetUserFile($file);
	return $found if -e $found;
	$found = App::Packager::GetResource($file);
	return $found if -e $found;
    }

    ( my $me = __PACKAGE__ ) =~ s;::;/;g;
    foreach ( @INC ) {
	return "$_/$me/user/$file" if -e "$_/$me/user/$file";
	return "$_/$me/res/$file"  if -e "$_/$me/res/$file";
	return "$_/$me/$file"      if -e "$_/$me/$file";
    }
    undef;
}

use lib ( grep { defined } ::findlib("CPAN") );

################ Documentation ################

=head1 NAME

App::Music::PlayTab - Print chords of songs in a tabular fashion.

=head1 SYNOPSIS

=head2 playtab

playtab [options] [file ...]

 Options:
   --transpose +/-N     transpose all songs
   --output XXX		set outout file
   --lilypond N		accept chords in LilyPond syntax, N = bpm
   --syntax		print chord syntax
   --ident		show identification
   --help		brief help message
   --verbose		verbose information

=head2 App::Music::PlayTab

 use App::Music::PlayTab;
 run();			# arguments in @ARGV
 run(@args);		# explicit arguments

 perl -MApp::Music::PlayTab -e run ...arguments...

=head1 DESCRIPTION

This utility program is intended for musicians. It produces tabular
chord diagrams that are very handy for playing rhythm guitar or bass
in jazz, blues, and popular music.

I wrote it since in official (and unofficial) sheet music, I find it
often hard to stick to the structure of the piece. Also, as a guitar
player, I do not need all the detailed notes and such that are only
important for melody instruments. And usually I cannot turn over the
pages while playing.

For more info and examples,
see http://johan.vromans.org/software/sw_playtab.html .

B<playtab> is just a trivial wrapper around the App::Music::PlayTab module.

=head1 COMMAND LINE OPTIONS

=over 8

=item B<--transpose> I<amount>

Transposes all songs by I<amount>. This can be B<+> or B<-> 11 semitones.

When transposing up, chords will be represented sharp if necessary;
when transposing down, chords will be represented flat if necessary.
For example, chord A transposed +1 will become A-sharp, but when
transposed -11 it will become B-flat.

=item B<--output> I<file>

Designates I<file> as the output file for the program.

=item B<--lilypond>

Interpet chord names according to LilyPond syntax.

=item B<--help>

Print a brief help message and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

More verbose information.

=item I<file>

Input file(s).

=back

=head1 INPUT SYNTAX

The input for playtab is plain ASCII. It contains the chords, the
division in bars, with optional annotations.

An example:

    !t Blue Bossa

    Bossanova
    =
    | c-9 ... | f-9 ... | d% . g7 . | c-9 ... |
    | es-9 . as6 . | desmaj7 ... | d% . g7 . | c-9 . d% g7 |

The first line, '!t' denotes the title of the song. Each song must
start with a title line.

The title line may be followed by one or more '!s', subtitles, for
example to indicate the composer.

The text "Bossanova" is printed below the title and subtitle.

The "=" indicates some vertical space. Likewise, you can use '-' and
'+' as '=', but with a different vertical spacing.

The next lines show the bars of the song. In the first bar is the c-9
chord (Cminor9), followed by three dots. The dots indicate that this
chord is repeated for all 4 beats of this bar. In the 3rd bar each
chord take two beats: d5% (d half dim), a dot, g7 and another dot.

Run playtab with B<-h> or B<--help> for the syntax of chords.

If you use "=" followed by some text, the printout is indented and the
text sticks out to the left. With this you can tag groups of bars, for
example the parts of a song that must be played in a certain order.
For example:

    !t Donna Lee
    !s Charlie Parker

    Order: A B A B

    = A
    | as . | f7 . | bes7 . | bes7 . |
    | bes-7 . | es7 . | as . | es-7 D7 |
    | des . | des-7 . | as . | f7 . |
    | bes7 . | bes7 . | bes-7 . | es7 . |

    = B
    | as . | f7 . | bes7 . | bes7 . |
    | c7 . | c7 . | f- . | c7#9 . |
    | f- . | c7 . | f- . | aso . |
    | as f7 | bes-7 es7 | as - | bes-7 es7 |

To see how this looks, see http://johan.vromans.org/software/sw_playtab.html .

You can modify the width of the bars with a '!w' control. Standard
width of a beat is 30. '!w +5' increases the width to 35. '!w 25' sets
it to 25. You get the idea. You can also change the height with '!h'
(default is 15) and margin with '!m' (default width is 40). You can
restore the margin to its default value with '<'. This will save the
current settings, and '!m' without argument will restore the saved
settings.

You can transpose an individual song with '!x I<amount>', where
I<amount> can range from -11 to +11, inclusive. A positive transpose
value will make sharps, a negative value will make flats.

'!n' enables bar numbering. '!n 0' disables numbering, '!n I<n>'
starts numbering at I<n>. I<n> may be negative, e.g., to skip
numbering an intro.

'!ly' or '!lilypond' enables LilyPond chord name recognition. If
followed by a '0', switches to classical chord name syntax.

Look at the examples, that is (currently) the best way to get grip on
what the program does.

Oh, I almost forgot: it can print guitar chord diagrams as well.
See "bluebossa", "sophisticatedlady" and some others.

Have fun, and let me know your ideas!

=head1 INPUT SYNTAX

  Notes: C, D, E, F, G, A, B.
  Raised with '#' or suffix 'is', e.g. A#, Ais.
  Lowered with 'b' or suffix 's' or 'es', e.g. Bes, As, Eb.

  Chords: note + optional modifiers.
  Chord modifiers Meaning                 [examples]
  --------------------------------------------------------------
  nothing         major triad             [C]
  - or min or m   minor triad             [Cm Fmin Gb-]
  + or aug        augmented triad         [Caug B+]
  o or 0 or dim   diminished triad        [Co D0 Fdim]
  --------------------------------------------------------------
  maj7            major 7th chord         [Cmaj7]
  %               half-diminished 7 chord [C%]
  6,7,9,11,13     chord additions         [C69]
  sus sus4, sus2  suspended 4th, 2nd      [Csus]
  --------------------------------------------------------------
  #               raise the pitch of the note to a sharp [C11#9]
  b               lower the pitch of the note to a flat [C11b9]
  --------------------------------------------------------------
  no              subtract a note from a chord [C9no11]
  --------------------------------------------------------------
  _ may be used to avoid ambiguity, e.g. C_#9 <-> C#9 <-> C#_9

  Other:          Meaning
  --------------------------------------------------------------
  .               Chord space
  -               Rest
  :               Repeats previous chord
  %               Repeat
  /               Powerchord constructor   [D/G D/E-]
  --------------------------------------------------------------

=head1 LILYPOND INPUT SYNTAX

  Notes: c, d, e, f, g, a, b.
  Raised with suffix 'is', e.g. ais.
  Lowered with suffix 'es', e.g. bes, ees.

  Chords: note + optional duration + optional modifiers.

  Duration = 1, 2, 4, 8, with possible dots, e.g., "2.".
  No duration means: use the duration of the previous chord.

  Modifiers are preceeded with a ":".

  Modifiers       Meaning                 [examples]
  --------------------------------------------------------------
  nothing         major triad             c4
  m               minor triad             c4:m
  aug             augmented triad         c4:aug
  dim             diminished triad        c4:dim
  --------------------------------------------------------------
  maj             major 7th chord         c4:maj
  6,7,9,11,13     chord additions         c4:7  c4:6.9 (dot required)
  sus sus4, sus2  suspended 4th, 2nd      c4:sus
  --------------------------------------------------------------
  +               raise the pitch of an added note   c4:11.9+
  -               lower the pitch of an added note   c4:11.9-
  --------------------------------------------------------------
  ^               subtract a note from a chord       c4:9.^11
  --------------------------------------------------------------

  Other:          Meaning
  --------------------------------------------------------------
  r               Rest                    r2
  s               Rest                    s4
  /               Powerchord constructor  d/g   d/e:m
  --------------------------------------------------------------

See also: http://lilypond.org/doc/stable/Documentation/user/lilypond/Chord-names

=head1 SEE ALSO

http://chordie.sourceforge.net/

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 1990,2016 by Johan Vromans.

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
