#! perl

use strict;
use warnings;

package Data::iRealPro::Input::MusicXML::Data;

our $VERSION = "0.01";

use parent qw( Exporter );

our @EXPORT;
our @EXPORT_OK;

our @clefs =
  ( 'C',				 #  0
    'G', 'D', 'A', 'E', 'B', 'F#', 'C#', #  1 .. 7
    'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F',	 # -6 .. -1
  );

push( @EXPORT_OK, '@clefs' );

our %durations =
  ( whole    => 4,
    half     => 2,
    quarter  => 1,
    eighth   => 0.5,
    '16th'   => 0.25,
    '32nd'   => 0.125,
  );

push( @EXPORT_OK, '%durations' );

our %note_numbers =
  ( 'C'	  =>  0,
    'C#'  =>  1,
    'Db'  =>  1,
    'D'	  =>  2,
    'D#'  =>  3,
    'Eb'  =>  3,
    'E'	  =>  4,
    'F'	  =>  5,
    'F#'  =>  6,
    'Gb'  =>  6,
    'G'	  =>  7,
    'G#'  =>  8,
    'Ab'  =>  8,
    'A'	  =>  9,
    'A#'  => 10,
    'Bb'  => 10,
    'B'	  => 11,
  );

push( @EXPORT_OK, '%note_numbers' );

# http://usermanuals.musicxml.com/MusicXML/Content/ST-MusicXML-kind-value.htm
our %harmony_kinds =
  (
    # Triads.
    major		  => "",
    minor		  => "",
    augmented		  => "",
    diminished		  => "",

    # Sevenths.
    dominant		  => "",
    'major-seventh'	  => "",
    'minor-seventh'	  => "",
    'diminished-seventh'  => "",
    'augmented-seventh'	  => "",
    'half-diminished'	  => "",
    'major-minor'	  => "",

    # Sixths.
    'major-sixth'	  => "",
    'minor-sixth'	  => "",

    # Ninths.
    'dominant-ninth'	  => "",
    'major-ninth'	  => "",
    'minor-ninth'	  => "",

    # 11ths.
    'dominant-11th'	  => "",
    'major-11th'	  => "",
    'minor-11th'	  => "",

    # 13ths.
    'dominant-13th'	  => "",
    'major-13th'	  => "",
    'minor-13th'	  => "",

    # Suspended.
    'suspended-second'	  => "",
    'suspended-fourth'	  => "",

    # Functional sixths.
    Neapolitan		  => "",
    Italian		  => "",
    French		  => "",
    German		  => "",

    # Other.
    pedal		  => "", # pedal-point bass
    power		  => "", # perfect fifth
    Tristan		  => "",

    # The "other" kind is used when the harmony is entirely composed of
    # add elements.
    other		  => "",

    # The "none" kind is used to explicitly encode absence of chords
    # or functional harmony.
    none		  => "",
  );

push( @EXPORT_OK, '%harmony_kinds' );

1;
