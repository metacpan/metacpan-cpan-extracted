#! perl

use warnings;
use strict;
use Carp qw( carp croak );
use utf8;

package Data::iRealPro::Input::MusicXML;

our $VERSION = '0.07';

use XML::LibXML;
#use DDumper;
use Encode qw( decode_utf8 encode_utf8 );

sub encode {
    my ( $self, $xml ) = @_;
    my $parser = XML::LibXML->new;
    my $opts = { no_cdata => 1 };
    if ( $self->{catalog} && -r  $self->{catalog} ) {
	$parser->load_catalog( $self->{catalog} );
    }
    else {
	$opts->{load_ext_dtd} = 0;
    }
    $parser->set_options( $opts );
    my $data = $parser->load_xml( string => $xml );

    # <score-partwise>
    #   <work>
    #      <work-title>Yellow Dog Blues</work-title>
    #   </work>
    #   <movement-title>Yellow Dog Blues</movement-title>
    #   <identification>
    #     <encoding>
    #        <software>MuseScore 2.0.3</software>
    #        ...
    #     </encoding>
    #   </identification>
    #   <defaults ... />
    #   <credit page="1" ... />
    #   <credit page="1" ... />
    #   <part-list>
    #      <score-part id="P1" ... />
    #   </part-list>
    #   <part id="P1" ... />
    # </score-partwise>

    # print DDumper($data);

    $self = bless { %$self }, __PACKAGE__;

    my $root = "/score-partwise";
    my $rootnode = $data->findnodes($root)->[0];

    my $song = { title => 'NoName',
		 composer => 'NoBody',
		 tempo => 100,
		 index => $self->{songix},
		 parts => [] };

    if ( my $d = $rootnode->fn1('movement-title') ) {
	$song->{title} = $song->{'movement-title'} = $d->to_literal;
	warn( "Title: ", decode_utf8($song->{title}), "\n" )
	  if $self->{debug};
    }
    if ( my $d = $rootnode->fn1('work/work-title') ) {
	$song->{title} = $song->{'work-title'} = $d->to_literal;
	warn( "Title: ", decode_utf8($song->{title}), "\n" )
	  if $self->{debug};
    }

    if ( my $d = $rootnode->fn1('identification/creator[@type=\'composer\']') ) {
	$song->{composer} = $d->to_literal;
	warn( "Composer: ", decode_utf8($song->{composer}), "\n" )
	  if $self->{debug};
    }

    if ( my $d = $rootnode->fn1('identification/encoding/software') ) {
	$song->{software} = $d->to_literal;
    }

    if ( $song->{software} =~ /^musescore/i ) {
	$self->{musescore} //= 1;
	# MuseScore puts the title top center, and the composer bottom right.
	my $composer = $rootnode->fn1(q{credit/credit-words} .
				      q{[@valign='bottom'][@justify='right']});
	$song->{composer} = $composer->to_literal
	  if $composer;
    }

    $self->{song} = $song;

    $self->_process( $rootnode, "part", \&process_part,
		     { path => $root } );

    # use DDumper; DDumper($self->{song});

    my $variant = 'irealpro';
    my $plname = "Import via MusicXML";
    my @songs;

    foreach ( @{ $song->{parts} } ) {
	push( @songs, $self->to_irealpro( $song, $_ ) );
    }

    # Build a playlist for the songs...
    my $pl = Data::iRealPro::Playlist->new
      ( variant      => $variant,
	songs        => \@songs,
	$plname ? ( name => $plname ) : (),
      );

    # Build a URI for the playlist...
    my $uri = Data::iRealPro::URI->new
      ( variant      => $variant,
	playlist     => $pl,
      );

    # And deliver.
    return $uri;

}

sub process_part {
    my ( $self, $part, $data, $ctx ) = @_;

    # <part id="P1">
    #   <measure ... />
    # </part>

    my $this = {};
    push( @{ $self->{song}->{parts} }, $this );

    $this->{id} = $data->fn1('@id')->to_literal;
    warn( "Part $part: ", decode_utf8($this->{id}), "\n")
      if $self->{debug};

    # print DDumper($data);

    $this->{sections} = [];
    $self->_process( $data, "measure", \&process_measure, $ctx );

}

sub process_measure {
    my ( $self, $measure, $data, $ctx ) = @_;

    # <measure number="24">
    #   <direction ... />
    #   <note ... />
    #   <harmony ... />
    #   <barline ... />
    # </measure>

    use Data::iRealPro::Input::MusicXML::Data qw( @clefs );

    my $this = $self->{song}->{parts}->[-1];

    use feature qw(state);
    state $lastchord;

    my $mark = "";
    foreach ( @{ $data->fn('direction/direction-type/rehearsal') } ) {
	$mark = $_->to_literal;
    }
    if ( !$mark && $self->{musescore} ) {
	foreach ( @{ $data->fn(q{direction/direction-type/words[@enclosure='rectangle']}) } ) {
	    $mark = $_->to_literal;
	}
    }

=begin xxx

    if ( $mark ) {
	push( @{ $this->{sections} },
	      { mark => $mark, measures => [] } );
    }
    elsif ( @{ $this->{sections} } == 0 ) {
	$this->{sections} = [ { measures => [] } ];
    }

=cut

    if ( @{ $this->{sections} } == 0 ) {
	$this->{sections} = [ { measures => [] } ];
    }
    $this = $this->{sections}->[-1];
    if ( $mark ) {
	$this->{mark} = $mark;
    }

    my $clef = "";
    my $mode = "major";
    foreach ( @{ $data->fn('attributes/key/*') } ) {
	if ( $_->nodeName eq "fifths" ) {
	    $clef = $clefs[$_->to_literal];
	}
	if ( $_->nodeName eq "mode" ) {
	    $mode = $_->to_literal;
	}
    }

    printf STDERR ( "Measure %2d: \"%s\" %s%s %s\n",
		    $measure,
		    $data->fn1('@number')->to_literal,
		    $mark ? "[$mark] " : "",
		    $clef ? ( $clef, $mode ) : ( "", "" ),
		  )
      if $self->{debug};

    $clef .= "-" if $mode eq 'minor';
    $self->{song}->{key} ||= $clef;

    # warn DDumper($data);

    if ( my $d = $data->fn1('sound/tempo') ) {
	$ctx->{tempo} = $d->to_literal;
	$ctx->{_parent}->{tempo} = $ctx->{tempo};
	print STDERR ( " Tempo: ", $ctx->{tempo}, "\n" )
	  if $self->{debug};
    }
    else {
	$ctx->{tempo} = $ctx->{_parent}->{tempo};
    }

    if ( my $d = $data->fn('attributes/time/*') ) {
	foreach ( @$d ) {
	    $ctx->{_parent}->{beats} = $ctx->{beats} = $_->to_literal
	      if $_->nodeName eq "beats";
	    $ctx->{_parent}->{'beat_type'} = $ctx->{'beat_type'} = $_->to_literal
	      if $_->nodeName eq "beat-type";
	}
	print STDERR ( " Beats: ",
		       $ctx->{beats}, "/", $ctx->{'beat_type'},
		       "\n" ) if $self->{debug};
	$this->{time} = $ctx->{beats} ."/". $ctx->{'beat_type'};
    }
    else {
	$ctx->{beats} = $ctx->{_parent}->{beats};
	$ctx->{'beat_type'} = $ctx->{_parent}->{'beat_type'};
    }

    if ( my $d = $data->fn1('attributes/staves') ) {
	$ctx->{staves} = $d->to_literal;
    }

    if ( my $d = $data->fn1('attributes/divisions') ) {
	$ctx->{_parent}->{divisions} =
	$ctx->{divisions} = $d->to_literal;
	print STDERR ( " Divisions: ", $ctx->{divisions}, "\n" )
	  if $self->{debug};
    }
    else {
	$ctx->{divisions} = $ctx->{_parent}->{divisions};
    }

    my ( $lbar, $rbar, $ending, $segno, $coda, $awords, $bwords );
    if ( my $d = $data->fn1(q{barline[@location='left']/ending[@type='start']} ) ) {
	foreach ( $d->attributes ) {
	    next unless $_->getName eq "number";
	    $ending = $_->getValue;
	}
    }
    if ( my $d = $data->fn1(q{barline[@location='right']/repeat[@direction='backward']} ) ) {
	$rbar = 'repeat';
    }
    if ( my $d = $data->fn1(q{barline[@location='left']/repeat[@direction='forward']} ) ) {
	$lbar = 'repeat';
    }
    if ( my $d = $data->fn1(q{direction[@placement='above']//words} ) ) {
	$awords = $d->to_literal;
    }
    if ( my $d = $data->fn1(q{direction[@placement='below']//words} ) ) {
	$bwords = $d->to_literal;
    }
    if ( my $d = $data->fn1(q{direction//coda} ) ) {
	$coda = 'coda';
	if ( $ctx->{_parent}->{has_coda} ) {
	    push( @{ $self->{song}->{parts}->[-1]->{sections} },
		  { measures => [] } );
	    $this = $self->{song}->{parts}->[-1]->{sections}->[-1];
	}
	$ctx->{_parent}->{has_coda} = 1;
    }

    if ( my $d = $data->fn1(q{direction//segno} ) ) {
	$segno = 'segno';
    }

    # Process note and harmony nodes, in order.
    my ( $n, $h );
    $ctx->{currentbeat} = 0;
    my @chords = ( "_" ) x $ctx->{beats};
    foreach ( @{ $data->fn('note | ./harmony') } ) {
	print STDERR ("== beat: ", $ctx->{currentbeat}, "\n" )
	  if $self->{debug};
	$self->process_note( ++$n, $_, $ctx )
	  if $_->nodeName eq "note";
	if ( $_->nodeName eq "harmony" ) {
	    $chords[$ctx->{currentbeat}] =
	      $self->process_harmony( ++$h, $_, $ctx );
	}
    }

    if ( $chords[0] eq "_" && $lastchord ) {
	$chords[0] = $lastchord;
    }
    push( @{ $this->{measures} },
	  { number => $data->fn1('@number')->to_literal,
	    chords => [ @chords ],
	    $ending ? ( ending => $ending ) : (),
	    $lbar ? ( lbar => $lbar ) : (),
	    $rbar ? ( rbar => $rbar ) : (),
	    $coda ? ( coda => $coda ) : (),
	    $segno ? ( segno => $segno ) : (),
	    $awords ? ( awords => $awords ) : (),
	    $bwords ? ( bwords => $bwords ) : (),
	  } );

    pop(@chords) while @chords && $chords[-1] eq "_";
    $lastchord = $chords[-1] if @chords;
}

sub process_note {
    my ( $self, $note, $data, $ctx ) = @_;

    use Data::iRealPro::Input::MusicXML::Data qw( %durations );

    # Duration, in beats.
    my $duration = 0;
    unless ( $data->fn1("grace") ) {
	$duration = $data->fn('duration')->[0]->to_literal
	  / $ctx->{divisions};
    }
    # Duration is the actual duration, dots included.
    # $duration *= 1.5 if $data->fn('dot');

    my $root;

    if ( my $d = $data->fn1('pitch') ) {
	$root = $d->fn('step')->[0]->to_literal;
	foreach ( @{ $d->fn('alter') } ) {
	    $root .= 'b' if $_->to_literal < 0;
	    $root .= '#' if $_->to_literal > 0;
	}
	if ( my $d = $d->fn1('octave') ) {
	    $root .= $d->to_literal;
	}
    }
    elsif ( $data->fn1('rest') ) {
	$root = 'rest';
    }

    printf STDERR ("Note %3d: %s %s x=%d d=%.2f s=%d\n",
		   $note,
		   $root,
		   eval { $data->fn('type')->[0]->to_literal } || "notype",
		   eval { $data->fn1('default-x')->to_literal } || 0,
		   $duration,
		   eval { $data->fn1('staff')->to_literal } || 1,
		  )
      if $self->{debug};

    $ctx->{currentbeat} += $duration
      unless $data->fn1('chord');
}

sub process_harmony {
    my ( $self, $harmony, $data, $ctx ) = @_;

#    warn DDumper($data);

    my $root = $data->fn1('root/root-step')->to_literal;
    foreach ( @{ $data->fn('root/root-alter') } ) {
	$root .= 'b' if $_->to_literal < 0;
	$root .= '#' if $_->to_literal > 0;
    }

    my $tquality = "";
    my $quality = $data->fn1('kind')->to_literal;
    if ( my $d = $data->fn1('kind/@text') ) {
	$tquality = $d->to_literal;
    }

    my $bass = eval { $data->fn1('bass/bass-step')->to_literal };

    my @d;
    foreach ( @{ $data->fn('degree') } ) {
	push( @d, [ $_->fn1('degree-value')->to_literal,
		    $_->fn1('degree-alter')->to_literal,
		    $_->fn1('degree-type')->to_literal ] );
    }

    printf STDERR ( "Harm %3d: %s%s%s %s\n",
		    $harmony, $root, $quality,
		    $bass ? "/$bass" : "",
		    $tquality )
      if $self->{debug};

    return [ $root, $quality, $tquality, $bass, @d ? \@d : () ];

}

################ Generating iRealPro data ################

sub to_irealpro {
    my ( $self, $song, $part ) = @_;
    my $variant = 'irealpro';

    # Build the song...

    my @composer = split( ' ', $song->{composer}       || "Composer" );
    @composer[0,1] = @composer[1,0] if @composer == 2;
    my $sung = Data::iRealPro::Song->new
      ( variant	       => $variant,
	title	       => $song->{title},
	composer       => "@composer",
	style	       => $song->{style}          || "Rock Ballad",
	key	       => $song->{key}            || "C",
	actual_tempo   => $song->{tempo}	  || "0",
	actual_style   => $song->{actual_style}   || "",
	actual_repeats => $song->{actual_repeats} || "",
     );

    my $irp = "";
    my $ix = 0;
    my $bpm = 4;
    my $neatify = $self->{neatify} || 0;
    my $suppress_upbeat = $self->{'suppress-upbeat'} || 0;
    my $condense = $self->{condense} || 0;
    my $musescore = $self->{musescore} || 0;
    my $suppress_text = $self->{'suppress-text'} || $musescore;

    my $secnum = 0;
    foreach my $s ( @{ $part->{sections} } ) {
	$secnum++;
	while ( $ix % 16 ) {
	    $irp .= " " if $neatify;
	    $ix++;
	}
	$irp .= "Y" if $neatify > 1;
	if ( my $mark = $s->{mark} ) {
	    $mark = 'A' unless $mark =~ /^[ABCD]$/;
	    $irp .= '[*' . $mark;
	}
	else {
	    $irp .= "[";
	}

	if ( $s->{time} ) {
	    $irp .= "," if $irp =~ /[[:alnum:]]$/;
	    $irp .= "T" . timesig( $s->{time} );
	    $bpm = $1 if $s->{time} =~ /(^\d+)/;
	}

	my $barnum = 0;
	foreach my $m ( @{ $s->{measures} } ) {
	    $barnum++;

	    if ( my $lbar = $m->{lbar} ) {
		$irp .= $lbar eq 'repeat' ? '{' : '|';
	    }

	    if ( my $ending = $m->{ending} ) {
		$irp .= "," if $irp =~ /[[:alnum:]]$/;
		$irp .= "N" . $ending;
	    }

	    if ( my $coda = $m->{coda} ) {
		$irp .= "," if $irp =~ /[[:alnum:]]$/;
		$irp .= "Q";
	    }

	    if ( my $segno = $m->{segno} ) {
		$irp .= "," if $irp =~ /[[:alnum:]]$/;
		$irp .= "S";
	    }

	    unless ( $suppress_text ) {
		if ( my $words = $m->{awords} ) {
		    $words =~ s/\s+$//;
		    $irp .= "<*72" . $words . ">";
		}
		if ( my $words = $m->{bwords} ) {
		    $words =~ s/\s+$//;
		    $irp .= "<*00" . $words . ">";
		}
	    }

	    if ( $suppress_upbeat
		 && $barnum == 1
		 && ( !@{ $m->{chords} }
		      || join("",@{$m->{chords}}) eq ("_" x $bpm)
		    ) ) {
		$barnum = 0;
		next;
	    }

	    my @c;
	    if ( $bpm < 4 ) {
		# Align 3/4 to 4/4.
		push( @{ $m->{chords} }, "_" ) while @{ $m->{chords} } < 4;
	    }

	    foreach my $c ( @{ $m->{chords} } ) {
		my $mapped = 'n'; # N.C.
		if ( defined $c ) {
		    $mapped = $self->irpchord($c);
		    unless ( defined $mapped ) {
			warn( sprintf( "Section %d, measure %d, ".
				       "chord \"$c\" is not mappable to iRealPro\n",
				       $secnum, $barnum ) );
			$mapped = 'n';
		    }
		}
		else {
		    warn( sprintf( "Section %d, measure %d, ".
				   "skipping undefined chord\n",
				   $secnum, $barnum ) );
		}
		push( @c, $mapped eq '_' ? " " : $mapped );
	    }

	    if ( $condense ) {
		my $c = "";
		foreach my $i ( 0 .. $#c ) {
		    if ( $c[$i] eq " " ) {
			$c .= " ";
			next;
		    }
		    $c .= "," if $c =~ /[[:alnum:]]$/;
		    # If there is space, append as normal.
		    if ( $i < $#c && $c[$i+1] eq " " ) {
			$c .= $c[$i];
		    }
		    # Otherwise, append condensed.
		    else {
			$c .= "s" . $c[$i] . "l";
		    }
		}
		# Small optimalisation for adjacent condensed entries.
		$c =~ s/l,s/,/g;
		warn(qq{"$c"\n}) if $self->{debug};

		# Append to output.
		$irp .= "," if $irp =~ /[[:alnum:]]$/;
		$irp .= $c;
	    }
	    else {
		foreach ( @c ) {
		    $irp .= "," if $irp =~ /[[:alnum:]]$/ && $_ ne ' ';
		    $irp .= $_;
		}
	    }

	    if ( my $rbar = $m->{rbar} ) {
		$irp .= $rbar eq 'repeat' ? '}' : '|';
	    }
	    else {
		$irp .= "|";
	    }
	    $ix += $bpm;
	}
	$irp =~ s/\|$//;
        $irp .= "]";
    }

    $irp .= " ";
    $sung->{data} = $irp;

    # And deliver.
    return $sung;
}

################ Chords ################

my %harmony_kinds =
  (
    # Triads.
    major		  => "",
    minor		  => "-",
    augmented		  => "+",
    diminished		  => "o",

    # Sevenths.
    dominant		  => "7",
    'major-seventh'	  => "^7",
    'minor-seventh'	  => "-7",
    'diminished-seventh'  => "o7",
    'augmented-seventh'	  => "+7",
    'half-diminished'	  => "h",
    'major-minor'	  => "-^7",

    # Sixths.
    'major-sixth'	  => "6",
    'minor-sixth'	  => "-6",

    # Ninths.
    'dominant-ninth'	  => "9",
    'major-ninth'	  => "^9",
    'minor-ninth'	  => "-9",

    # 11ths.
    'dominant-11th'	  => "11",
    'major-11th'	  => "^11",
    'minor-11th'	  => "-11",

    # 13ths.
    'dominant-13th'	  => "13",
    'major-13th'	  => "^13",
    'minor-13th'	  => "-13",

    # Suspended.
    'suspended-second'	  => "sus2",
    'suspended-fourth'	  => "sus4",

  );

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
     "sus4"		=> 'sus',
  );

sub irpchord {
    my ( $self, $c ) = @_;
    return $c unless ref($c) eq 'ARRAY';
    my ( $root, $quality, $text, $bass, $degree ) = @$c;
    if ( exists $harmony_kinds{$quality} ) {
	$text = $harmony_kinds{$quality};
    }
    else {
	$text = "?";
    }

    $degree ||= [];

    foreach ( @$degree ) {
	my ( $value, $alter, $type ) = @$_;
	next unless $type eq 'add' || $type eq 'alter';
	$text .= 'b' if $alter < 0;
	$text .= '#' if $alter > 0;
	$text .= $value;
    }

    $bass = $bass ? "/$bass" : "";

    # Prefer 7sus to sus47.
    $text =~ s/sus47/7sus/;

    return $root . $text . $bass if exists $chordqual{$text};

    # Override weird combinations of degree alterations with 'alt'.
    return $root . '7alt' . $bass
      if $self->{'override-alt'} && $text eq "7b5#5b9#9";

    # Otherwise, yield the quality as text.
    return $root . '*' . $text . $bass . '*';
}

################ Time Signatures ################

my $_sigs;

sub timesig {
    my ( $time ) = @_;
    $_sigs ||= { "2/2" => "22",
		 "3/2" => "32",
		 "2/4" => "24",
		 "3/4" => "34",
		 "4/4" => "44",
		 "5/4" => "54",
		 "6/4" => "64",
		 "7/4" => "74",
		 "2/8" => "28",
		 "3/8" => "38",
		 "4/8" => "48",
		 "5/8" => "58",
		 "6/8" => "68",
		 "7/8" => "78",
		 "9/8" => "98",
		"12/8" => "12",
	       };

    $_sigs->{ $time }
      || Carp::croak("Invalid time signature: $time");
}

################ Convenience ################

# Process a subtree, identified by $key.
sub _process {
    my ( $self, $data, $key, $handler, $ctx ) = @_;

    my @nodes = $data->fn($key);
    warn("No $key nodes found\n"), return unless @nodes;

    my $ix = 0;
    foreach ( @nodes ) {

	# Establish context and link in parent context, if any.
	my $c = $self->{_ctx}->{$key} =
	  { path => join("/", $ctx->{path}, $key) };
	$c->{_parent} = $ctx if $ctx;

	$handler->( $self, $ix+1, $_, $c );

	$ix++;
    }
}

# Convenient short for subnodes. Returns a nodelist.
sub XML::LibXML::Node::fn {
    $_[0]->findnodes( './' . $_[1] );
}

# Convenient short for single subnode. Returns a node.
sub XML::LibXML::Node::fn1 {
    my $expr = './' . $_[1] . '[1]';
    $expr =~ s/^\.\/\[/[/;
    my $nl = $_[0]->findnodes($expr);
    return unless $nl;
    $nl->[0];
}

1;
