#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound - Create Csound scores and instruments

=cut
#_}
package Csound;

use warnings;
use strict;
use utf8;

use Carp;

our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

    use Csound::Composition;
    use Csound::Instrument;

    my $composition    = Csound::Composition->new();
    my $instrument_one = Csound::Instrument->new(…);
    my $instrument_two = Csound::Instrument->new(…);

    # go from there …

=cut
#_}
#_{ Methods
#_{
=head1 METHODS
=cut
#_}
sub is_note { #_{
#_{ POD
=head2 is_note

    $is_a_note     = Csound::is_note('d5');
    $is_a_note     = Csound::is_note('f11');
    $is_a_note     = Csound::is_note('c♯4');
    $is_a_note     = Csound::is_note('b♭9');

    $is_not_a_note = Csound::is_note('foo');

=cut
#_}

  my $possible_note = shift;

  carp "Pass a possible note" unless $possible_note;

  return 1 if ($possible_note =~ /^[a-g][♯♭]?[12]?\d$/);
  return 0;                              

} #_}
sub note_to_pch {
#_{ POD
=head2 note_to_pch

    my $pch = Csound::note_to_pch('d♯4'); # returns 4.03


=cut
#_}

  my $note = shift;

  croak "note is not a note" unless $note =~ /^([a-g])([♯♭]?)([12]?\d)$/;

  my $letter = $1;
  my $sign   = $2 // '';
  my $octave = $3;



  my $note_nr;
  $note_nr =  0 if $letter eq 'c';
  $note_nr =  2 if $letter eq 'd';
  $note_nr =  4 if $letter eq 'e';
  $note_nr =  5 if $letter eq 'f';
  $note_nr =  7 if $letter eq 'g';
  $note_nr =  9 if $letter eq 'a';
  $note_nr = 11 if $letter eq 'b';

  $note_nr += 12*$octave;
  
# =  ((ord($letter) - ord('c')) ) + 12 * $octave;

  $note_nr-- if $sign eq '♭';
  $note_nr++ if $sign eq '♯';

  my $fract_out   = $note_nr % 12;
  my $octave_out  = ($note_nr - $fract_out)/12;

  return sprintf("%d.%02d", $octave_out, $fract_out);


}
#_}
#_{ POD: Copyright

=head1 Copyright

Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

#_}
#_{ Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Csound >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
