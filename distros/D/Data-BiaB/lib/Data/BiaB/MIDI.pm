#! perl

package Data::BiaB::MIDI;

BEGIN {
our $VERSION = 0.11;
}

use Data::BiaB;
BEGIN { Data::BiaB->VERSION($VERSION) }

=head1 NAME

Data::BiaB::MIDI - MIDI generator for Data::BiaB

=head1 SYNOPSIS

This module provides MIDI generation for Data::BiaB.

Example:

    use Data::BiaB;
    use Data::BiaB::MIDI;

    # Load an existing song.
    my $biab = Data::BiaB->new();
    $biab->load("Vaya_Con_Dios.mgu");

    # Create MIDI.
    $biab->makemidi("Vaya_Con_Dios.midi");

For convenience, you can run the module from the command line:

  perl lib/Data/BiaB/MIDI.pm Vaya_Con_Dios.mgu

This will produce a MIDI file named C<__new__.midi>.

=cut

package Data::BiaB;

use warnings;
use strict;
use Carp qw( carp croak );

my @keys =
  ( '/','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bb','B',
    'C#','D#','F#','G#','A#',
    'Cm','Dbm','Dm','Ebm','Em','Fm','Gbm','Gm','Abm','Am','Bbm','Bm',
    'C#m','D#m','F#m','G#m','A#m',
  );

my %chords =
  (
    "2"        => [ qw( 0 2 7 ) ],
    "sus2"     => [ qw( 0 2 7 ) ],
    "dim"      => [ qw( 0 3 6 ) ],
    "0"        => [ qw( 0 3 6 ) ],
    "dim7"     => [ qw( 0 3 6  9 ) ],
    "m7b5"     => [ qw( 0 3 6 10 ) ],
    "ø"        => [ qw( 0 3 6 10 ) ],
    "m7b5"     => [ qw( 0 3 6 10 ) ],
    "m9b5"     => [ qw( 0 3 6 11 14 ) ],
    "m"        => [ qw( 0 3 7 ) ],
    "m#5"      => [ qw( 0 3 7 ) ],
    "m6"       => [ qw( 0 3 7  9 ) ],
    "m69"      => [ qw( 0 3 7  9 14 ) ],
    "m7"       => [ qw( 0 3 7 10 ) ],
    "m9"       => [ qw( 0 3 7 10 14 ) ],
    "m11"      => [ qw( 0 3 7 10 14 17 ) ],
    "m13"      => [ qw( 0 3 7 10 14 17 21 ) ],
    "mmaj7"    => [ qw( 0 3 7 11 ) ],
    "mM7"      => [ qw( 0 3 7 11 ) ],
    "maug"     => [ qw( 0 3 8 ) ],
    "m7#5"     => [ qw( 0 3 8 10 ) ],
    "7b5"      => [ qw( 0 4 6 10 ) ],
    "7b5b9"    => [ qw( 0 4 6 10 13 ) ],
    "9b5"      => [ qw( 0 4 6 10 14 ) ],
    "13b5"     => [ qw( 0 4 6 10 14 17 21 ) ],
    "7b5#9"    => [ qw( 0 4 6 10 15 ) ],
    "maj7#5"   => [ qw( 0 4 6 11 ) ],
    ""         => [ qw( 0 4 7 ) ],
    "maj"      => [ qw( 0 4 7 ) ],
    "6"        => [ qw( 0 4 7  9 ) ],
    "maj6"     => [ qw( 0 4 7  9 ) ],
    "maj69"    => [ qw( 0 4 7  9 14 ) ],
    "69"       => [ qw( 0 4 7  9 14 ) ],
    "7"        => [ qw( 0 4 7 10 ) ],
    "7b9"      => [ qw( 0 4 7 10 13 ) ],
    "13b9"     => [ qw( 0 4 7 10 13 17 21 ) ],
    "7b9#11"   => [ qw( 0 4 7 10 13 18 ) ],
    "9"        => [ qw( 0 4 7 10 14 ) ],
    "7#9"      => [ qw( 0 4 7 10 14 ) ],
    "11"       => [ qw( 0 4 7 10 14 17 ) ],
    "7b13"     => [ qw( 0 4 7 10 14 17 20 ) ],
    "9b13"     => [ qw( 0 4 7 10 14 17 20 ) ],
    "13"       => [ qw( 0 4 7 10 14 17 21 ) ],
    "13sus"    => [ qw( 0 4 7 10 14 17 21 ) ],
    "13+"      => [ qw( 0 4 7 10 14 17 22 ) ],
    "7#11"     => [ qw( 0 4 7 10 14 18 ) ],
    "9#11"     => [ qw( 0 4 7 10 14 18 ) ],
    "13#11"    => [ qw( 0 4 7 10 14 18 21 ) ],
    "7#9b13"   => [ qw( 0 4 7 10 15 17 20 ) ],
    "13#9"     => [ qw( 0 4 7 10 15 17 21 ) ],
    "maj7"     => [ qw( 0 4 7 11 ) ],
    "M7"       => [ qw( 0 4 7 11 ) ],
    "maj7"     => [ qw( 0 4 7 11 ) ],
    "maj9"     => [ qw( 0 4 7 11 14 ) ],
    "maj9"     => [ qw( 0 4 7 11 14 ) ],
    "maj11"    => [ qw( 0 4 7 11 14 17 ) ],
    "maj13"    => [ qw( 0 4 7 11 14 17 21 ) ],
    "maj13"    => [ qw( 0 4 7 11 14 17 21 ) ],
    "maj9#11"  => [ qw( 0 4 7 11 14 18 ) ],
    "maj13#11" => [ qw( 0 4 7 11 14 18 21 ) ],
    "aug"      => [ qw( 0 4 8 ) ],
    "+"        => [ qw( 0 4 8 ) ],
    "aug7"     => [ qw( 0 4 8 10 ) ],
    "7#5"      => [ qw( 0 4 8 10 ) ],
    "7#5"      => [ qw( 0 4 8 10 ) ],
    "7+"       => [ qw( 0 4 8 10 ) ],
    "7#5b9"    => [ qw( 0 4 8 10 13 ) ],
    "9#5"      => [ qw( 0 4 8 10 14 ) ],
    "7#5#9"    => [ qw( 0 4 8 10 15 ) ],
    "sus"      => [ qw( 0 5 7 ) ],
    "sus4"     => [ qw( 0 5 7 ) ],
    "4"        => [ qw( 0 5 7 ) ],
    "sus7"     => [ qw( 0 5 7 10 ) ],
    "7sus"     => [ qw( 0 5 7 10 ) ],
    "7susb9"   => [ qw( 0 5 7 10 13 ) ],
    "7sus#9"   => [ qw( 0 5 7 10 15 ) ],
    "7sus#5"   => [ qw( 0 5 8 10 ) ],
    "5b"       => [ qw( 0 6 ) ],
    "5"        => [ qw( 0 7 ) ],
  );

my @midikeys   = (split(/ /, "C G D A E B F# C# Cb Gb Db Ab Eb Bb F"));
my @midinotess  = (split(/ /, "C C# D D# E F G G# A A# B"));
my @midinotesf  = (split(/ /, "C Db D Eb E F G Ab A Bb B"));
my %midinotes;

sub makemidi {
    my ( $self, $file ) = @_;

    require MIDI;
    use constant EV_TIME => 1;
    use constant TICKS => 120;

    unless ( %midinotes ) {
	for ( my $i = 0; $i < @midinotess; $i++ ) {
	    $midinotes{$midinotess[$i]} = $i;
	    $midinotes{$midinotesf[$i]} = $i;
	}
    }

    my $bpm = 4;		# beats per measure

    my $key = chordroot($self->{key_nr});
    warn("key=$key");
    my $minor = 0;

    if ( $key =~ /^(.+)m$/ ) {
	$minor++;
	$key = $1;
    }
    $key = $midinotes{$key};
    warn("key=$key");
    $key = 14 - $key if $key > 7;
    warn("key=$key $minor");
    my @pre = (
	       [ 'set_tempo', 0, 60000000 / $self->{bpm} ],
	       [ 'time_signature', 0, $bpm, 2, 24, 8 ],
	       [ 'key_signature', 0, $key, $minor ],
	      );

    my @ev;
    my $time = 0;
    my ( $onset, $chan, $pitch, $velo, $flags, $dur );
    $onset = $bpm*TICKS;
    $chan = 2;
    $velo = 40;
    $dur = TICKS;
    my $chord;
    my $beats = 0;

    my @chords;
    # The chords consist of three parts:
    # - the intro
    # - the repeatable part (chorus)
    # - the coda
    # The starting and ending bar numbers for the chorus are known.

    my @c = @{$self->{chords}};
    my $start = $self->{start_chorus_bar};
    my $end = $self->{end_chorus_bar};

    # Start with the intro, if any.
    push( @chords, @c[ 0 .. $bpm*$start-1] ) if $start > 1;

    # Append the chorus repetitions.
    for ( my $r = $self->{number_of_repeats}; $r > 0; $r-- ) {
	push( @chords, @c[ $bpm*($start-1) .. $bpm*$end-1 ] );
    }

    # Append coda part, if any.
    push( @chords, @c[ $bpm*$end .. $#c ] ) if $end < $#c;

    # Now turn the chords into a MIDI track.
    @ev = ();
    foreach ( @chords ) {
	$chord = $_ if defined;	# undefined -> use previous

	if ( ++$beats > $bpm ) {
	    # There are (always?) 4 chord slots per measure.
	    next if $beats < 4;
	    $beats = 0;
	}

	$time += TICKS;

	my ( $root, $name, $type ) =
	  $chord =~ /^\s*(\d+)\s+\d+\s+(\S+)\s+(.*)/;
	my @notes = @{$chords{$type}};
	unless ( @notes ) {
	    warn("Unknown chord[$chord @ $time]: $name$type\n");
	    $onset += TICKS;
	    next;
	}

	warn("CHORD[$time $chord] $root $name$type (@notes)\n")
	  if defined && $self->{debug};

	# All chord notes on ...
	foreach ( @notes ) {
	    # 60 = central C.
	    push( @ev, [ 'note_on', $onset, $chan, 60+$_+$root-1, $velo ] );
	    $onset = 0;
	}
	# ... and off a beat later.
	$onset = TICKS;
	foreach ( @notes ) {
	    push( @ev, [ 'note_off', $onset, $chan, 60+$_+$root-1, $velo ] );
	    $onset = 0;
	}
    }

    # Add preamble and make a track.
    my $chords = MIDI::Track->new( { events => [ @pre, @ev ] } );
    my @tracks = ( $chords );

    # Now for the melody.
    @ev = ();
    foreach ( @{ $self->{melody} } ) {
	( $onset, $chan, $pitch, $velo, $flags, $dur ) = @$_;

	# Skip notes we won't (cannot) handle.
	next unless $flags == 144 || $flags == 148 || $flags == 147;
	next unless $chan && $chan < 16;

	# Subtrackt lead in.
	$onset -= $bpm*TICKS;

	# Make MIDI.
	push( @ev, [ 'note_on',  $onset,      $chan, $pitch, $velo ] );
	push( @ev, [ 'note_off', $onset+$dur, $chan, $pitch, $velo ] );
    }

    unless ( @ev ) {
	carp("No melody?");
    }
    else {
	# Sort on timestamp.
	@ev = sort { $a->[EV_TIME] <=> $b->[EV_TIME] } @ev;

	# Convert to delta times.
	$time = 0;
	foreach my $e ( @ev ) {
	    carp("NEGATIVE DELTA \@ $time: @{[$e->[EV_TIME]-$time]}\n")
	      if $e->[EV_TIME] < $time;
	    # Make time relative.
	    ($time, $e->[EV_TIME]) = ($e->[EV_TIME], $e->[EV_TIME]-$time);
	}

	# Create a MIDI track and add it to the tracks.
	my $melody = MIDI::Track->new( { events => [ @pre, @ev ] } );
	push( @tracks, $melody );
    }

    # Create the MIDI Opus.
    my $op = MIDI::Opus->new
      ( { format => 1,
	  ticks  => TICKS,
	  tracks => \@tracks,
	} );

    # And save.
    $op->write_to_file( $file || '__new__.midi' );
}


1; # End of Data::BiaB

package main;

unless ( caller ) {
    use Data::BiaB;
    my $b = Data::BiaB->new( debug => 1 )->load (shift )->parse;
    $b->makechords;
    $b->makemidi;
}

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 BUGS AND SUPPORT

See L<Data::BiaB>.

=head1 COPYRIGHT & LICENSE

Copyright 2016 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
