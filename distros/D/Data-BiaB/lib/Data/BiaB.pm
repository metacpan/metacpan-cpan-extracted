#! perl

package Data::BiaB;

=head1 NAME

Data::BiaB - Analyze Band-in-a-Box data files

=cut

our $VERSION = 0.11;

=head1 SYNOPSIS

This module provides methods to read Band-in-a-Box data files and
extract some useful information from them.

Band-in-a-Box is an excellent tool for creating professional music and
accompanying tracks. I've been using it for many years but had to
abandon it when I phased out Microsoft Windows PCs.

Example:

    use Data::BiaB;

    # Load an existing song.
    my $biab = Data::BiaB->new();
    $biab->load("Vaya_Con_Dios.mgu");

    # This will show what was gathered.
    use Data::Dumper;
    print Dumper($biab);

=head1 NOTE

Many BiaB files fail loading and parsing. If you have a recent version
of Band-in-a-Box its MusicXML export feature will be a much better
alternative.

This is a hobby project. It is pre-alpha, under development, works for
me, caveat emptor and so on. Have fun!

=cut

use warnings;
use strict;
use Carp qw( carp croak );
use Data::Dumper;
use Data::Hexify;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

sub new {
    my ( $pkg, %opts ) = @_;
    bless { %opts }, $pkg;
}

sub load {
    my ( $self, $file ) = @_;
    $self->{_file} = $file;
    $self->{_size} = -s $file;
    open( my $fh, '<:raw', $file )
      or croak("$file: $!");
    $self->{_raw} = do { local $/; <$fh> };
    close($fh);

    $self;
}

sub parse {
    my ( $self ) = @_;

    my $data = $self->{_raw};
    my $inx = 0;
    my $i;
    my $val;

    my $dd1 = sub {
	warn(Hexify( $data, { start => $_[0], length => $_[1] } ))
	  if $self->{debug} >= 1;
    };
    my $dd2 = sub {
	warn(Hexify( $data, { start => $_[0], length => $_[1] } ))
	  if $self->{debug} >= 2;
    };
    my $gb = sub { unpack( "C", substr($data, $inx++, 1) ) };

    # Skip 1.
    $dd1->( $inx, 1 );
    $inx++;

    # Ttitle.
    $val = $gb->();
    warn("Title length = $val\n") if $self->{debug} > 2;
    $dd2->( $inx-1, 1+$val );
    $self->{title} = substr($data, $inx, $val );
    warn("Title = $self->{title}\n");
    $inx += $val;

    # Skip 2.
    $dd1->( $inx, 2 );
    $inx += 2;

    # Style/Key/BPM.
    $dd2->( $inx, 3 );
    $self->{basic_style} = $gb->();
    $self->{key_nr} = $gb->();
    $self->{bpm} = $gb->();

    # Styles;
    $i = 0;
    my $tally = 0;
    my $first = 0;
    $self->{stylemap} = {};
    while ( $i < 256 ) {
	$val = $gb->();
	if ( $val ) {
	    $dd2->( $inx-1, 1 );
	    $self->{stylemap}->{$i-1} = $val;
	    warn("Style: $val @ $i\n") if $self->{debug} > 2;
	    $tally++;
	    $i++;
	}
	else {
	    $dd2->( $inx-1, 2 );
	    $val = $gb->();
	    croak("Format error (zero offset) in styles") unless $val;
	    $i += $val;
	}
    }
    if ( $i > 256 ) {
	croak("Format error (offset $i mismatch) in styles");
    }
    warn("Read: $tally styles\n");

    # Chord types.
    $i = 1;
    $self->{ctypes} = [];
    $tally = 0;
    # 1021 = 4 * 255 + 1
    # 255 measures of 4 chords.
    while ( $i < 1021 ) {
	$val = $gb->();
	if ( $val ) {
	    $dd2->( $inx-1, 1 );
	    $self->{ctypes}->[$i-1] = $val;
	    $first //= $i-1;
	    warn("Ctype: [", $inx-1, "] $val @ $i\n") if $self->{debug} > 1;
	    $tally++;
	    $i++;
	}
	else {
	    $dd2->( $inx-1, 2 );
	    $val = $gb->();
	    croak("Format error (zero offset) in ctypes") unless $val;
	    $i += $val;
	}
    }
    # The sequence ends with 00 ff 00 ff 00 nn to sum up to 1021.
    if ( $i > 1021 ) {
	croak("Format error (offset $i mismatch) in ctypes");
    }
    $first++;
    warn("Read: $tally ctypes, first @ $first, last @ ", scalar(@{$self->{ctypes}}), "\n");

    # Chord names.
    $i = 1;
    $self->{cnames} = [];
    $tally = 0;
    $first = undef;
    while ( $i < 1022 ) {
	$val = $gb->();
	if ( $val ) {
	    $dd2->( $inx-1, 1 );
	    $self->{cnames}->[$i-1] = $val;
	    $first //= $i-1;
	    warn("Cname: [", $inx-1, "] $val @ $i\n") if $self->{debug} > 1;
	    $tally++;
	    $i++;
	}
	else {
	    $dd2->( $inx-1, 2 );
	    $val = $gb->();
	    croak("Format error (zero offset) in cnames") unless $val;
	    $i += $val;
	}
    }
    # The sequence ends with 00 ff 00 ff 00 nn to sum up to 1022.
    # Yes, really...???
    if ( $i > 1022 ) {
	croak("Format error (offset $i mismatch) in cnames");
    }
    $first++;
    warn("Read: $tally cnames, first @ $first, last @ ", scalar(@{$self->{cnames}}), "\n");

    $dd2->( $inx, 3 );

    # A song consists of lead-in (bar 0), intro, chorus, and coda.
    # The chorus is repeated a number of times.
    $self->{start_chorus_bar} = $gb->();	# chorus start
    $self->{end_chorus_bar} = $gb->();		# chorus ends
    $self->{number_of_repeats} = $gb->();

    #$dd1->($inx, 1024);

    if ( substr($data, $inx, $inx+2560)
	 =~ /^(.*?\x{42})((?:\x{5}.|\x{6}..|\x{7}...|\x{8}....|\x{9}.....|\x{a}......|\x{b}.......|\x{c}........)\.STY)/ ) {
	$val = substr($2,1);
	$self->{stylefile} = $val;
	warn("Style $val @ ", $inx+length($1), " ($inx+", length($1), ")\n");
    }
    # Although the length is flexible, it seems to be filled to the max
    # with garbage (or a default XXXXXXXX.STY).
    $inx += length($1);
    $inx += 13;

    if ( substr($data, $inx, $inx+256) =~ /^(.*?)\x{00}\x{ff}\x{00}\x{0d}(..)/ ) {
	$val = unpack("v", $2);
	warn("NumNotes $val @ ", $inx+length($1), " ($inx+", length($1), ")\n");
	$self->{numnotes} = $val;
	$inx += length($1) + 6;
    }

    my ( $onset, $chan, $pitch, $velo, $dur, $unk );
    my @m;
  RETRY:
    warn("Search for melody from $inx...\n") if $self->{debug};
    if ( substr($data, $inx) =~ /^(.*?)\x{a0}\x{b0}(\x{c0}|\x{c1})/s ) {
	$inx += 3 + length($1);
	warn( sprintf("melody %02x @ %d, %d notes\n",
		      ord($2), $inx, $self->{numnotes}) );
	while ( $inx < length($data)-12  ) {
	    $dd2->($inx,12);
	    ( $onset, $unk, $pitch, $velo, $chan, $dur ) =
	      unpack("VCCCCV", substr($data, $inx, 12));

	    if ( @m == 0
		 && ( $pitch > 100 || $velo > 127 || $chan > 15
		      || $dur > 7200 || $onset > 7200 ) ) {
		$dd1->($inx,12);
		warn("insane values in melody -- retrying...\n");
		goto RETRY;
	    }
	    # $pitch = pitchname($pitch);
	    push( @m, [ $onset, $chan, $pitch, $velo, $unk, $dur ] );
	    $inx += 12;
	    if ( @m == $self->{numnotes} - 1) {
		last;
	    }
	    if ( $inx >= length($data)-12 ) {
		warn("Oops");
		last;
	    }
	}
    }
    else {
	warn("No melody found\n");
    }
    if ( @m != $self->{numnotes} ) {
	warn("Missing or incomplete melody (",
	     scalar(@m), " notes, should have been ",
	     $self->{numnotes}, ")\n");
    }
    $self->{melody} = \@m;

    if ( $inx < length($data) ) {
	$dd1->( $inx, length($data) - $inx );
    }

    $self;
}

sub pitchname {
    my ( $p ) = @_;
    my $n = [ "C", "C#", "D", "D#", "E", "F", "F#",
	      "G", "G#", "A", "A#", "B" ]->[$p % 12];
    # BiaB pitch is 1 octave low.
    $n . int($p/12);
}

my %ctypes =
  (   "0"    =>  "",
      "1"    =>  "",
      "2"    =>  "maj",
      "3"    =>  "5b",
      "4"    =>  "aug",
      "5"    => "6",
      "6"    => "maj7",
      "7"    => "maj9",
      "8"    => "maj9#11",
      "9"    => "maj13#11",
      "10"   => "maj13",
      "12"   => "+",
      "13"   => "maj7#5",
      "14"   => "69",
      "15"   => "2",
      "16"   => "m",
      "17"   => "maug",
      "18"   => "mM7",
      "19"   => "m7",
      "20"   => "m9",
      "21"   => "m11",
      "22"   => "m13",
      "23"   => "m6",
      "24"   => "m#5",
      "25"   => "m7#5",
      "26"   => "m69",
      "32"   => "m7b5",
      "33"   => "dim",
      "34"   => "m9b5",
      "40"   => "5",
      "56"   => "7+",
      "57"   => "+",
      "58"   => "13+",
      "64"   => "7",
      "65"   => "13",
      "66"   => "7b13",
      "67"   => "7#11",
      "70"   => "9",
#      "70"   => "9b13",
      "73"   => "9#11",
      "74"   => "13#11",
      "76"   => "7b9",
      "77"   => "13b9",
      "79"   => "7b9#11",
      "82"   => "7#9",
      "83"   => "13#9",
      "84"   => "7#9b13",
      "85"   => "9#11",
      "88"   => "7b5",
      "89"   => "13b5",
      "91"   => "9b5",
      "93"   => "7b5b9",
      "96"   => "7b5#9",
      "99"   => "7#5",
      "103"  => "9#5",
      "105"  => "7#5b9",
      "109"  => "7#5#9",
      "113"  => "7alt",
      "128"  => "7sus",
      "129"  => "13sus",
      "134"  => "11",
      "140"  => "7susb9",
      "146"  => "7sus#9",
      "163"  => "7sus#5",
      "177"  => "4",
      "184"  => "sus",
  );

sub chordroot {
    my ( $nr ) = @_;
    # Convert the byte for chord root to a string.
    my @roots = ( '/','C','Db','D','Eb','E','F','Gb','G',
		  'Ab','A','Bb','B','C#','D#','F#','G#','A#');
    my @bassflat = ('B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb');
    my @basssharp = ('B','C','C#','D','D#','E','F','F#','G','G#','A','A#');

    my $root = $roots[$nr % 18];
    if ( $nr > 18 ) {
	my $bass = "";
	if ( $root =~ /b/ ) {
	    $bass = $bassflat[(int $nr / 18 + $nr % 18) % 12]; #flat slash
	}
	else {
	    $bass = $basssharp[(int $nr / 18 + $nr % 18) % 12]; #sharp slash
	}
	$root .= "/" . $bass;
    }
    return $root;
}

sub makechords {
    my ( $self ) = @_;
    my @cn = @{ $self->{cnames} };
    my @ct = @{ $self->{ctypes} };
    my @c;
    carp("Expecting same number of chord names " . scalar(@cn) .
	  " and chord types " . scalar(@ct))
      unless @cn == @ct;
    for ( my $i = 0; $i < @cn; $i++ ) {
	if ( defined $cn[$i] ) {
	    if ( defined $ct[$i] ) {
		push( @c,
		      sprintf("%3d %3d %s %s",
			      $cn[$i], $ct[$i],
			      chordroot($cn[$i]), $ctypes{"".$ct[$i]}));
	    }
	    else {
		warn("Chord ", 1+$i, ": name = $cn[$i], no type\n");
	    }
	}
	else {
	    if ( defined $ct[$i] ) {
		warn("Chord ", 1+$i, ": no name, type = $ct[$i]\n");
	    }
	    else {
		push( @c, undef );
	    }
	}
    }

    $self->{chords} = \@c;
}

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-biab at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-BiaB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::BiaB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-BiaB>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-BiaB>

=back

=head1 ACKNOWLEDGEMENTS

PG Music inc., for making Band-in-a-Box. I've used Band-in-a-Box for
several years with great pleasure.

The ancient and abandoned Band-In-A-Box File Converter 'biabconverter'
by Alain Brenzikofer inspired me to write this.

=head1 COPYRIGHT & LICENSE

Copyright 2016 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::BiaB

package main;

unless ( caller ) {
    use Data::Dumper;
    my $b = Data::BiaB->new( debug => 1 )->load (shift )->parse;
    $b->makechords;

    if ( 1 ) {
	for ( qw( _raw stylemap ctypes cnames  ) ) {
	    delete $b->{$_};
	}
	$b->{melody} =
	  [ map { $_->[2] = Data::BiaB::pitchname($_->[2]); $_ }
	    @{$b->{melody}} ];
	warn(Dumper($b));
    }
}
