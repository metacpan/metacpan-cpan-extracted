#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound::Composition

=cut
#_}
package Csound::Composition;

use warnings;
use strict;

use Carp;

use Csound::Score;
use Csound::ScoreStatement::t;

our $VERSION = $Csound::VERSION;
#_{ Synopsis

=head1 SYNOPSIS

    use Csound::Composition;

    my $composition=Csound::Composition->new();

=cut
#_}
#_{ Description
=head1 DESCRIPTION

A Csound composition. Used to create
a L<Csound::Orchestra> and a L<Csound::Score>.

=over

=cut
#_}
#_{ Methods
=head1 METHODS
=cut
sub new { #_{
#_{ POD
=head2 new


    my $composition = Csound::Composition->new();

=cut
#_}

  my $class = shift;

  my $self  = {};

  bless $self, $class;

  die unless $self->isa('Csound::Composition');

  $self->{score    } = Csound::Score->new();
  $self->{orchestra} = Csound::Orchestra->new();

  return $self;

} #_}
sub t { #_{
#_{ POD
=head2 t

    my $t = $composition->t($start_tempo);

Returns a L<< t statement|Csound::ScoreStatement::t >> which can be used to control the tempo at various beats in the composition:

    $t->tempo($t₁, 70); # Increase tempo from t₁ 
    $t->tempo($t₂, 90); #   until
    $t->tempo($t₃, 95); # t₃.

=cut

  my $self        = shift;
  my $start_tempo = shift;

  my $t    = Csound::ScoreStatement::t->new($start_tempo);
  $self->{score}->t($t);

#_}
} #_}
sub play { #_{
#_{ POD
=head2 play

    my $composition = Csound::Composition->new();

    $composition->play($instr, $t_start, $t_duration, @params);

=cut
#_}

  my $self = shift;

  die unless $self->isa('Csound::Composition');

  my $instr = shift;
  croak "play requires an instrument" unless $instr->isa('Csound::Instrument');

  $self->{orchestra}->use_instrument($instr);
  $self->{score}->play($instr, @_);

} #_}
sub write { #_{
#_{ POD
=head2 play


    $composition->write('filename');

Writes C<filename.orc> and C<filename.sco>.
 

=cut
#_}

  my $self = shift;

  die unless $self->isa('Csound::Composition');

  my $filename_without_suffix = shift;

  #
  #  Note Csound::Orchestra::write uses a Csound::Score reference ($self->{score})
  #  because it might write to the Csound::Score (notably the f statements.).
  #  Therefore, $self->{orchestra}->write() must be called before
  #  $self->{score}->write().
  #
  $self->{orchestra}->write($filename_without_suffix, $self->{score});
  $self->{score    }->write($filename_without_suffix);

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
