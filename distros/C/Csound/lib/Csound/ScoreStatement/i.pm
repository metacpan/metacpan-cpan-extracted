#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound::ScoreStatement

L<http://www.csounds.com/manual/html/ScoregensTop.html>

=cut
#_}

package Csound::ScoreStatement::i;

use warnings;
use strict;
# use 5.10.0; # state

use Carp;

use Csound::ScoreStatement;

our $VERSION = $Csound::VERSION;
our @ISA     = qw(Csound::ScoreStatement);
#_{ Synopsis

=head1 SYNOPSIS

    use Csound::ScoreStatement::i;

    ...

=cut
#_}
#_{ Description
=head DESCRIPTION

The C<f> statement causes a so called GEN subroutine to place values in a stored function table.

The syntax is

    f tableNumber actionTime size genRoutine …

=cut
#_}
#_{ Methods
#_{
=head1 METHODS
=cut
#_}
sub new { #_{
#_{ POD
=head2 new

This method should not be called by the end user, it should be called by L<Csound::Instrument/i>.

=cut
#_}


  my $class = shift;

  my $instr    = shift;
  my $t_start  = shift;
  my $t_len    = shift;
  my @params   = @_;

  croak "No instrument passed" unless $instr->isa('Csound::Instrument');

  my $self  = {};
  bless $self, $class;
  croak unless $self->isa('Csound::ScoreStatement::i');

  $self -> {instr   } = $instr;
  $self -> {t_start } = $t_start;
  $self -> {t_len   } = $t_len;
  $self -> {params  } =\@params;

  return $self;

} #_}
sub score_text { #_{
#_{ POD
=head2 score_text

    my $txt = $i->score_text();

Returns the text to be written into the score.

=cut
#_}


  my $self = shift;
  die unless $self->isa('Csound::ScoreStatement::i');

  my $score_text = sprintf ('i%d %s %s', $self->instrument_nr(), $self->{t_start}, $self->{t_len});

  if (@{$self->{params}}) {

    $score_text .= ' ';

    $score_text .= join ' ', @{$self->{params}};
  }

  return $score_text;

} #_}
sub instrument_nr { #_{
#_{ POD
=head2 instrument_nr

    my $inr = $i->instrument_nr();

Returns the number of the instrument to which this C<I statement> belongs.

=cut
#_}


  my $self = shift;

  croak unless $self->isa('Csound::ScoreStatement::i');

  die "\$sself->instr is not an Csound::Instrument" unless $self->{instr}->isa('Csound::Instrument');

  return $self->{instr}->{nr};

} #_}
#_}
#_{ POD: Copyright

=head1 Copyright
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}

'tq84';

