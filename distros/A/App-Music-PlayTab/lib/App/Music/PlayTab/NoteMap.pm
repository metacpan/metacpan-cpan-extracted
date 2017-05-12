#! perl

# Author          : Johan Vromans
# Created On      : Wed Aug 22 22:33:31 2007
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr 19 16:24:17 2011
# Update Count    : 6
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::NoteMap;

use strict;
use warnings;

our $VERSION = "1.005";

use base qw(Exporter);
our @EXPORT_OK;
BEGIN {
    @EXPORT_OK = qw(@FNotes @SNotes note_to_key key_to_note);
}

# All notes, using sharps.
our @SNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C', 'C#','D', 'D#','E', 'F', 'F#','G', 'G#','A', 'A#','B');

# All notes, using flats.
our @FNotes =
  # 0    1    2    3    4    5    6    7    8    9    10   11
  ('C', 'Db','D', 'Eb','E', 'F', 'Gb','G', 'Ab','A', 'Bb','B');

# The current mapping. This can be changed by set_flat/set_sharp.
my $Notes = \@SNotes;

# Reverse mapping (plain notes only).
my %Notemap;
for ( my $i = 0; $i < @SNotes; $i++ ) {
    $Notemap{$SNotes[$i]} = $i if length($SNotes[$i]) == 1;
}

sub set_flat {
    my $Notes = \@FNotes;
}

sub set_sharp {
    my $Notes = \@SNotes;
}

sub note_to_key {
    $Notemap{uc shift()};
}

sub key_to_note {
    my ($key, $flat) = @_;
    return $Notes->[$key] unless defined $flat;
    return $FNotes[$key] if $flat;
    $SNotes[$key];
}

1;

__END__
=head1 NAME

App::Music::PlayTab::NoteMap - Common data and routines.

=head1 SYNOPSIS

  use App::Music::PlayTab::NoteMap;
  print $App::Music::PlayTab::NoteMap::SNotes[2];   # prints 'D'

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.

App::Music::PlayTab::NoteMap contains common data and routines, some
of these are exported on demand.

@FNotes contains all the note names, using sharps. E.g., $FNotes[3] is
'D#'. @FNotes can be imported on demand.

@SNotes contains all the note names, using flats. E.g., $FNotes[3] is
'Eb'. @SNotes can be imported on demand.

Subroutine note_to_key returns the ordinal value (key) for a given
plain note. It returns undef for an unrecognized argument.
note_to_key can be imported on demand.

Subroutine key_to_note returns the note for a given key. The optional
second argument can be used to select the use of sharps or flats. If
the second argument is not used, the currently selected mode is
applied.
key_to_note can be imported on demand.

Subroutines set_flat and set_sharp can be used to select whether note
names must be produced with flats or sharps.

