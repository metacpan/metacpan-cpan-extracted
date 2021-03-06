#! perl

# Data::iRealPro::Output::MMA -- produce MMA song

# Author          : Johan Vromans
# Created On      : Mon Jan  7 08:20:16 2019
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jan 20 22:22:42 2019
# Update Count    : 481
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Output::MMA;

my $VERSION = "0.01";

use parent qw( Data::iRealPro::Output::Base );

use Data::iRealPro::URI;
use Data::Dumper;
use Encode qw(encode_utf8);

my $regtest = $ENV{IRP_REGTEST};

my %stype = ( i => "Intro",
	      v => "Verse",
	      coda => "Coda",
	    );

sub options {
    my $self = shift;
    [ @{ $self->SUPER::options }, qw( split dir ) ];
}

sub process {
    my ( $self, $u, $options ) = @_;

    for ( qw( trace debug verbose ) ) {
	$self->{$_} = $options->{$_} if exists $options->{$_};
    }

    unless ( $self->{split} ) {

	$self->{output} ||= $options->{output} || "__new__.mma";

	if ( $u->{transpose} ) {
	    foreach my $song ( @{ $u->{playlist}->{songs} } ) {
		# Do not change key to actual.
		local $song->{_transpose} = 0;

		$song->{key} = $song->xpose($song->{key} // "C");
		if ( $song->{actual_key} ne '' ) {
		    $song->{actual_key} =
		      ( $song->{actual_key} + $song->{transpose} ) % 12;
		}
		$song->tokenize;
		$song->{data} = $song->{dataxp} if $song->{dataxp};
	    }
	}

	if ( ref( $self->{output} ) ) {
	    ${ $self->{output} } = $self->to_mma($u);
	}
	else {
	    open( my $fd, ">:utf8", $self->{output} )
	      or croak( "Cannot create ", $self->{output}, " [$!]\n" );
	    print $fd $self->to_mma($u);
	    close($fd);
	}
	return;
    }

    my $outdir = $self->{dir} || "";
    $outdir .= "/" if $outdir && $outdir !~ m;/$;;
    make_path( $outdir, {} ) unless -d $outdir;

    foreach my $song ( @{ $u->{playlist}->{songs} } ) {
	# Do not change key to actual.
	local $song->{_transpose} = 0;

	if ( $song->{transpose} ) {
	    $song->{key} = $song->xpose($song->{key} // "C");
	    if ( $song->{actual_key} ne '' ) {
		$song->{actual_key} =
		  ( $song->{actual_key} + $song->{transpose} ) % 12;
	    }
	    $song->tokenize;
	    $song->{data} = $song->{dataxp} if $song->{dataxp};
	}

	# Make a playlist with just this song.
	my $pls = Data::iRealPro::Playlist->new( song => $song );

	# Make an URI for this playlist.
	my $uri = Data::iRealPro::URI->new( playlist => $pls );

	# Write it out.
	my $title = $song->{title};
	# Mask dangerous characters.
	$title =~ s/[:?\\\/*"<>|]/@/g;
	my $file = $outdir.$title.".mma";
	my $out = encode_utf8($file);
	open( my $fd, '>:utf8', $out )
	  or die( "$out: $!\n" );
	print $fd $self->to_mma($uri);
	close($fd);
	warn( "Wrote $out\n" )
	  if $self->{verbose};
    }
}

sub to_mma {
    my ( $self, $u ) = @_;

    my $pl = $u->{playlist};
    my $title;
    if ( $pl->{name} ) {
	$title = $pl->{name};
    }
    else {
	$title = $pl->{songs}->[0]->{title};
    }
    my $vv = $regtest ? "" : " version $Data::iRealPro::VERSION";

    my $song = $u->{playlist}->{songs}->[0];
    my $tempo = $song->{actual_tempo} || 120;

    my $time_d;
    my $time_n;
    my $time = "4/4";
    foreach ( @{ $song->tokens } ) {
	next unless /time (\d\/\d)/;
	$time = $1;
	last;
    }
    ( $time_d, $time_n ) = $time =~ m;^(\d+)/(\d+)$;;

    my @t = split( ' ', $song->{composer} );
    @t[0,1] = @t[1,0] if @t == 2;
    my $me = "Data::iRealPro $Data::iRealPro::VERSION";
    my @mma = ( <<EOD );
// Title: @{[ $song->{title} ]}
// Style: @{[ $song->{style} ]}
// Composer: @t
// Converted from iReal by $me

MIDIText @{[ $song->{title} ]}
MIDIText MMA input generated by $me

KeySig @{[ key2mma($song->{key}) ]}
Time $time_d
TimeSig $time
Tempo $tempo

EOD

    my $mma = "";
    my $s = $self->interpret($song);
    my $mcnt = 0;
    my $in_intro = 1;
    my $grepeat = $song->{actual_repeats} || 3;

    my $has_jumps;
    foreach ( @{ $s->{content} } ) {
	next unless $_->{hasjumps};
	$has_jumps++;
	last;
    }

    push( @mma, "Set SongForms $grepeat\n" );
    push( @mma, "\nLabel Capo\n" ) if $has_jumps;

    foreach my $section ( @{ $s->{content} } ) {
	#print "section ", $section->{type}, "\n";
	next unless @{ $section->{content} };
	my $type = $section->{type};
	next if $type eq "hspace";

	if ( $mma ) {
	    push( @mma, $mma );
	}
	$mma = "";

	if ( $in_intro && $type ne 'i' ) {
	    $mma .= "\nRepeat         // song form\n";
	    $in_intro = 0;
	}

	# iRealPro has two styles of song form repeats. Normally,
	# the coda part comes after the song form. However, when
	# jumps are used, the coda part becomes part of the song form.
	elsif ( $type eq "coda" && !$has_jumps ) {
	    $mma .= "\n" . endrepeat('$SongForms');
	    $grepeat = 0;
	}

	$mma .= "\n// Section: " . ($stype{$type}//$type) . "\n";
	$mma .= "Label Coda\n" if $has_jumps && $type eq "coda";
	$mma .= "Groove " . style2mma( $song->{style} ) . "\n";
	foreach my $item ( @{ $section->{content} } ) {
	    #print "item ", $item->{type}, "\n";

	    if ( $item->{type} eq "measure" ) {
		$mcnt++;
		my $res = sprintf("%3d", $mcnt);
		my @chords;
		foreach my $i ( @{ $item->{content} } ) {
		    # printf( "%3d  %s\n", $mcnt, "@$i" );
		    foreach my $j ( @$i ) {
			if ( $j =~ /^chord\s+(\S+)/ ) {
			    push( @chords, chord2mma($1) );
			}
			elsif ( $j =~ /^advance / ) {
			    push( @chords, "/" );
			}
			elsif ( $j =~ /^time\s+(\S+)/ ) {
			    warn("Time signature change: $time -> $1\n")
			      unless $1 eq $time;
			}
			elsif ( $j eq "segno" ) {
			    $mma .= "Label Segno\n";
			    next;
			}
			else {
			    $res .= " /* $j? */";
			}
		    }
		}
		if ( @chords < $time_d ) {
		    if ( @chords == 1 ) {
			# Okay, MMA will fill.
		    }
		    elsif ( @chords == 2 ) {
			splice( @chords, 1, 0, ("/") x int($time_d/2) );
		    }
		}
		while ( $chords[-1] eq "/" ) {
		    pop(@chords);
		}
		$res .= " @chords";
		$res .= "   /* " . $item->{jump}->{text} ." */"
		  if $item->{jump};
		$mma .= $res . "\n";
	    }
	    elsif ( $item->{type} eq "repeat start" ) {
		push( @mma, $mma );
		$mma = "Repeat\n";
	    }
	    elsif ( $item->{type} =~ /repeat end(.*)/ ) {
		$mma .= "RepeatEnd$1\n";
	    }
	    else {
		warn("OOPS: ", $item->{type}, "\n");
	    }
	}
    }

    push( @mma, $mma ) if $mma;
    push( @mma, "\n" . endrepeat('$SongForms') );

    join( "", @mma );
}

sub endrepeat {
    my ( $n ) = @_;
    my $res = "RepeatEnd";
    if ( $n =~ /^\$/ ) {
	$res .= " NoWarn $n";
    }
    elsif ( $n && $n ne "2" ) {
	$res .= " $n";
    }
    $res . "\n";
}

sub interpret {
    my ( $self, $song ) = @_;

    my $res = $self->_interpret1($song);
    foreach ( @{ $res->{content} } ) {
	$self->_interpret2($_);
	$self->_interpret3($_);
    }

    if ( $self->{debug} ) {
	$Data::Dumper::Deepcopy = 1;
	$Data::Dumper::Sortkeys = 1;
	warn Dumper($res);
    }

    return $res;
}

# Filter, and break into sections.
sub _interpret1 {
    my ( $self, $song ) = @_;
    my $tokens = [ @{ $song->tokens } ];

    while ( $tokens->[0] =~ /^advance|hspace/ ) {
	shift(@$tokens);
    }
    while ( $tokens->[-1] =~ /^advance|hspace/ ) {
	pop(@$tokens);
    }
    unless ( $tokens->[0] =~ /^start (?:repeat|section)/ ) {
	warn("Invalid section start: ", $tokens->[0], "\n");
    }

    my $res = { tokens => [ @$tokens ],
		content => [] };
    my $section;		# current section

    my $add_section = sub {
	push( @{$res->{content}}, { %$section } )
	  if $section && @{ $section->{tokens} };
    };

    my $new_section = sub {
	$add_section->();
	$section = { type    => "section",
		     tokens  => [],
		   };
    };

    $new_section->();

    for ( my $tp = 0; $tp < @$tokens; $tp++ ) {
	my $t = $tokens->[$tp];

	# Treat marked repeat as a section start.
	if ( $t eq "start repeat" && $tokens->[$tp+1] =~ /^mark/
	     && @{ $section->{tokens} } ) {
	    unshift( @$tokens, $t );
	    $t = "start section";
	    # Fall through...
	}

	if ( $t eq "start section" ) {
	    $new_section->();
	    next;
	}

	if ( $t =~ /^hspace\s+(\d+)$/ ) {
	    next;
	}
	if ( $t eq "small" || $t eq "large" ) {
	    next;
	}

	if ( $t =~ /^mark\s+(.+)$/ ) {
	    $section->{type} = $1;
	    next;
	}

	if ( $t eq "end section" ) {
	    $new_section->();
	    next;
	}

	if ( $t =~ /^chord (\(.+\))/ ) {
	    $t = "text $1";
	}

	push( @{ $section->{tokens} }, $t );

	if ( $t eq "end" ) {
	    $new_section->();
	    next;
	}

    }

    $add_section->();

    return $res;
}

# Process repeat sections.
sub _interpret2 {
    my ( $self, $section ) = @_;
    my @tokens = @{ $section->{tokens} };

    my $in_repeat;
    my $repeatpending;
    my $alternatives = 0;
    my $lastalternative;

    my $tp;

    my $peek = sub {
	my ( $pat ) = @_;
	foreach ( @tokens[ $tp+1 .. $#tokens ] ) {
	    return 1 if /$pat/;
	    return if /^chord|advance|end|start/;
	}
	return;
    };

    for ( $tp = 0; $tp < @tokens; $tp++ ) {
	my $t = $tokens[$tp];
	# printf STDERR ("%2d: %s\n", $tp, $t );

	if ( $t eq "start repeat" ) {
	    $tokens[$tp] = "repeat start";
	    $in_repeat = 1;
	    $alternatives = 0;
	    $tokens[$lastalternative] = "repeat end"
	      if defined $lastalternative;
	    $lastalternative = undef;
	    $repeatpending = 2;
	    next;
	}

	# Implied repeat at start of section.
	if ( $t eq "end repeat" || $t =~ /^alternative / ) {
	    if ( !$in_repeat ) {
		unshift( @tokens, "repeat start" );
		$in_repeat = 1;
		$tp++;
		$repeatpending //= 2;
	    }
	}

	# [ A | B | N1 C } N2 D |   will play A B C A B D, but
	# [ A | B } N1 C } N2 D |   will play A B A B C A B A B D
	if ( $t eq "end repeat" ) {
	    if ( $peek->(qr/^alternative/) ) {
		if ( $alternatives ) {
		    splice( @tokens, $tp, 1 );
		    $tp--;
		    next;
		}
		unshift( @tokens, "repeat start" );
		$repeatpending //= 2;
		$tp++;
	    }
	    $tokens[$tp] = "repeat end";
	    $tokens[$tp] .= " " . $repeatpending
	      if $repeatpending != 2;
	    $lastalternative = undef;
	    next;
	}

	if ( $t =~ /^text\s+\d+\s+(\d+)x$/ ) {
	    $repeatpending = $1;
	    next;
	}

	if ( $t =~ /^alternative\s+(\d+)$/ ) {
	    if ( $1 > $alternatives+1 && defined $lastalternative ) {
		$tokens[$lastalternative] = "repeat ending " . ($1-$alternatives);
	    }
	    $tokens[$tp] = "repeat ending";
	    $alternatives = $1;
	    $lastalternative = $tp;
	    next;
	}
    }

    $tokens[$lastalternative] = "repeat end"
      if defined $lastalternative;

    $section->{tokens} = \@tokens;
}

sub _interpret3 {
    my ( $self, $section ) = @_;
    my $tokens = [ @{ $section->{tokens} } ];
    my @tokens;

    my $measure;		# current measure
    my $cell;			# current cell

    my $new_cell = sub {
	$cell = [];
    };

    my $new_measure = sub {
	$new_cell->();
	push( @{ $section->{content} }, { %{ $measure } } )
	  if $measure && @{ $measure->{content} };
	$measure = { type    => "measure",
		     content => [],
		   };
    };

    $new_measure->();
    $section->{content} = [];

    my $i = 0;
    my $barskip = 0;
    my $in_repeat;
    my $repeatpending;

    while ( @$tokens ) {
	my $t = shift(@$tokens);
	$i++;

	my $done = 0;
	# warn( $t, $barskip ? "*\n" : "\n" );

	if ( $t =~ /^chord (\(.+\))/ ) {
	    $t = "text $1";
	}

	push( @tokens, $t );

	if ( $t =~ /^coda/ ) {
	    if ( @{ $section->{content} } == 0 && @{ $measure->{content} } == 0 ) {
		$section->{type} = $t;
	    }
	    else {
		$measure->{jump} = { text => "Coda", al => "coda" };
		$section->{hasjumps} = 1;
	    }
	    next;
	}

	if ( $barskip ) {
	    if ( $t =~ /^(?:bar|end.*|start.*|repeat*)$/ ) {
		$barskip = 0;
	    }
	    else {
		next;
	    }
	}

	if ( $t eq "bar" || $t =~ /^repeat/ ) {
	    $new_measure->();
	    next if $t eq "bar";
	    push( @{ $section->{content} }, { type => $t } );
	    next;
	}

	if ( $t =~ /^(chord\s+(.*)|advance\s+\d+)$/ ) {
	    push( @$cell, $t );
	    push( @{ $measure->{content} }, [ @$cell ] );
	    $new_cell->();
	    next;
	}

	if ( $t eq "measure repeat single" ) {
	    $measure = $section->{content}->[-1];
	    $barskip = 1;
	    next;
	}

	if ( $t =~ /^measure repeat double$/ ) {
	    push( @{ $section->{content} }, $section->{content}->[-2] );
	    $measure = $section->{content}->[-2];
	    $barskip = 1;
	    next;
	}

	if ( $t =~ /^text \d+ (.*)/ ) {
	    if ( my $jump = isjump($1) ) {
		$section->{hasjumps} = 1;
		$measure->{jump} = $jump;
	    }
	    next;
	}

	if ( $t eq "small" || $t eq "large" ) {
	    next;
	}

	push( @$cell, $t );
    }
    $new_measure->();
    $section->{tokens} = \@tokens;
}

my %chordqual =
  (''		   => '',
   '+'		   => '+',
   '-#5'	   => 'm#5',
   '-'		   => 'm',
   '-11'	   => 'm11',
   '-6'		   => 'm6',
   '-69'	   => 'm69',
   '-7'		   => 'm7',
   '-7b5'	   => 'm7b5',
   '-9'		   => 'm9',
   '-^7'	   => 'mM7',
   '-^9'	   => 'mM9',
   '-b6'	   => 'mb6',	# ???
   '11'		   => '11',
   '13#11'	   => '13#11',
   '13#9'	   => '13#9',
   '13'		   => '13',
   '13b9'	   => '13b9',
   '13sus'	   => '13sus',
   '13x11'	   => '13#11',
   '13x9'	   => '13#9',
   '2'		   => '2',
   '5'		   => '5',
   '6'		   => '6',
   '69'		   => '69',
   '7#11'	   => '7#11',
   '7#5'	   => '+7',
   '7#9#11'	   => '7#9#11',
   '7#9#5'	   => '+7#9',
   '7#9'	   => '7#9',
   '7#9b5'	   => '7b5#9',
   '7'		   => '7',
   '7alt'	   => '7alt',
   '7b13'	   => '7b13',
   '7b13sus'	   => '7b13sus', # ???
   '7b5'	   => '7b5',
   '7b9#11'	   => '7b9#11',
   '7b9#5'	   => '7#5b9',
   '7b9#9'	   => '7b9#9',	# ???
   '7b9'	   => '7b9',
   '7b9b13'	   => '7b9b13',	# ???
   '7b9b5'	   => '7b5b9',
   '7b9sus'	   => '7b9sus',
   '7b9x11'	   => '7b9#11',
   '7b9x5'	   => '7#5b9',
   '7b9x9'	   => '7b9#9',	# ???
   '7sus'	   => '7sus4',
   '7susadd3'	   => '7sus(add3)', # ???
   '7x11'	   => '7#11',
   '7x5'	   => '7#5',
   '7x9'	   => '7#9',
   '7x9b5'	   => '7b5#9',
   '7x9x11'	   => '7#9#11',
   '7x9x5'	   => '+7#9',
   '9#11'	   => '9#11',
   '9#5'	   => '+9',
   '9'		   => '9',
   '9b5'	   => '9b5',
   '9sus'	   => '9sus4',
   '9x11'	   => '9#11',
   '9x5'	   => '+9',
   '^'		   => 'M7',
   '^13'	   => 'M13',
   '^7#11'	   => 'M7#11',
   '^7#5'	   => '+M7',
   '^7'		   => 'M7',
   '^9#11'	   => 'M9#11',
   '^9'		   => 'M9',
   'add9'	   => 'add9',
   'alt'	   => 'alt',
   'h'		   => 'ø',	# dim or dim7 ?
   'h7'		   => 'dim',
   'h9'		   => 'h9',	# ???
   'm#5'	   => 'm#5',	# ???
   'm'		   => 'm',
   'm11'	   => 'm11',
   'm6'		   => 'm6',
   'm69'	   => 'm69',
   'm7'		   => 'm7',
   'm7b5'	   => 'm7b5',
   'm9'		   => 'm9',
   'mb6'	   => 'mb6',	# ???
   'mv7'	   => 'mM7',
   'mv9'	   => 'mM9',
   'mx5'	   => 'm#5',	# ???
   'o'		   => 'dim',
   'o7'		   => 'dim7',
   'p'		   => 'aug',
   'sus'	   => 'sus4',
   'v'		   => '^',
   'v13'	   => '^13',
   'v7'		   => '^7',
   'v7x11'	   => 'M7#11',
   'v7x5'	   => '+M7',
   'v9'		   => 'M9',
   'v9x11'	   => 'M9#11',
  );

my $pc;

sub chord2mma {
    my ( $chord ) = @_;

    my $bass;
    if ( $chord =~ m;^(.+)/(.+)$; ) {
	$bass = $2;
	$chord = $1;
    }
    if ( $chord eq "W" ) {
	$chord = $pc;
    }
    else {
	$pc = $chord;
    }

    if ( $chord =~ /^N\.?C\.?/ ) {
	$chord = "z";
    }

    unless ( $chord =~ /^([ABCDEFGWz][b\#]?)(.*)/ ) {
	Carp::croak("Invalid chord key: $chord");
    }

    my ( $root, $mod ) = ( $1, $2 );

    if ( defined($chordqual{$mod}) ) {
	$root .= $chordqual{$mod};
    }
    else {
	Carp::croak("Invalid chord modifier: $chord");
    }

    $root .= "/$bass" if $bass;
    return $root;
}

sub key2mma {
    my ( $key ) = @_;

    unless ( $key =~ /^([ABCDEFGW][b#]?)([-m])?$/ ) {
	Carp::croak("Invalid key: $key");
    }

    my ( $root, $min ) = ( $1, $2 );
    $root .= $min ? " minor" : " major";

    return $root;

}

sub style2mma {
    my ( $style, $section ) = @_;
    return "CountrySwing";
}

sub isjump {
    my ( $code ) = @_;

    return unless
    $code =~ m{ ^
		D\. ([CS]) \. \s+ al \s+
		  ( Coda | Fine | (?:1st|2nd|3rd) \s+ End )
		$
	      }xoi;

    my $al = lc($2);
    $al = $1 if $al =~ /^(\d)/;
    { text => $code, da => $1 eq "C" ? "capo" : "segno", al => $al }
}

1;
