#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound::Instrument

=cut
#_}
package Csound::Instrument;

use warnings;
use strict;
use Carp;
use 5.10.0; # state

use Csound::ScoreStatement::i;

our $VERSION = $Csound::VERSION;

#_{ Synopsis

=head1 SYNOPSIS

    use Csound::Instrument;

    ...

=cut
#_}
#_{ Description
=head DESCRIPTION


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

    my $composition = Csound::Composition->new(…);

    my $instr = Csound::Instrument->new(
      {
        composition => $composition,
        parameters  => ['amplitude', 'foo_1', 'foo_2']
      }
    );

If the parameter C<composition> is passed with a reference to a L<< Csound::Composition >>, the instrument's L</play> method is shorthand for
C<< $composition->play($instr, …) >>.

Most instrument play notes. However, to indicate that an instrument doesn't play a note (such as a high hat or a noise etc.),
the flag C<no_note> can be given.

    my $instr = Csound::Instrument->new(
      $composition,   
      {
        parameters => ['amplitude', 'foo_1', 'foo_2'],
        no_note => 1
      }
    );

=cut
#_}

  state $_instr_no = 0;

  my $class  = shift;
  my $params = shift // {};

  my $self   = {};

  if ($params->{parameters}) {
    $self->{parameters} = delete $params->{parameters}
  }
  else {
    $self->{parameters} = [];
  }
  if ($params->{composition}) {
    croak "composition must be a Csound::Composition" unless $params->{composition}->isa('Csound::Composition');
    $self->{composition} = delete $params->{composition};
  }

  $self->{no_note} = delete $params->{no_note} // 0;

  bless $self, $class;

  $self->{nr} = ++$_instr_no;

  $self->definition(delete $params->{definition}) if $params->{definition};

  return $self;

} #_}
sub definition { #_{
#_{ POD
=head2 definition

=cut
#_}

  my $self       = shift;
  my $definition = shift;

  $self->{definition} = $definition;
} #_}
sub play { #_{
#_{ POD
=head2 new

    $instr->play($t_start, $duration, 'f♯5', …);

When the instrument was L<constructed|/new> with the C<composition> parameter, this is a shorthand for

    $composition->play($instr, $t_start, $duration, 'f♯5', …);

=cut
#_}
  
  my $self = shift;

  croak "I don't have a composition to play this instrument on" unless $self->{composition};
  $self->{composition}->play($self, @_);

} #_}
sub plays_note { #_{
#_{ POD
=head2 new

    my $yes_no = $instr->plays_note();

In most cases, an instrument will play a note.
When the flag/parameter C<no_note> was given in L</new>, the instrument
also doesn't play a note.

=cut
#_}
  
  my $self = shift;

  return ! $self->{no_note};

} #_}
sub i { #_{
#_{ POD
=head2 i

    $instr -> i($t_start, $t_len, …);

Creates an L<i statement|Csound::ScoreStatement::i>. It should not be called by the end user. Rather, the user
should call L<Csound::Score/play>.

=cut
#_}

  my $self    = shift;
  my $t_start = shift;
  my $t_len   = shift;
  my @params  = grep { defined } @_;

  croak unless $self->isa('Csound::Instrument');

  my $expected_param_cnt = @{$self->{parameters}};
  $expected_param_cnt++ if $self->plays_note();

  croak (sprintf("expected %d parameters but was given %d", $expected_param_cnt, scalar @params)) unless @params == $expected_param_cnt;

  my $i = Csound::ScoreStatement::i->new($self, $t_start, $t_len, @params);

  return $i;

} #_}
sub orchestra_text { #_{

#_{ POD
=head2 orchestra_text

    my $score = Csound::Score->new(…);
    my $txt = $instr->orchestra_text($score);

Returns the text to be written into the score.

Sometimes, the instrument needs to have access to the score (notably for the f statements required in the C<oscil> opcode family). Therefore,
the method needs the C<$score> parameter.

=cut
#_}

  my $self  = shift;
  my $score = shift;
  die unless $self->isa('Csound::Instrument');

  my $orchestra_text = sprintf("instr %d\n\n", $self->{nr});


  my $param_no = 4;
  if ($self->plays_note) {
# unless ($self->{no_note}) {
     $orchestra_text .= "  i_freq init cpspch(p4)\n";
     $param_no++;
  }

  for my $param (@{$self->{parameters}}) {
     $orchestra_text .= sprintf("  i_%s init p%d\n", $param, $param_no++);
  }

  if ($self->{definition}) {

    my $definition = $self->{definition};
#   $orchestra_text .= $self->{definition};

    $definition =~ s{
      \@FUNCTABLE\(\ *(\d+)((?:\ *,\ *[0-9.]+)+)\ *\)
    }
    {
      my $gen_no = $1;
      my $parameters = $2;
      $parameters =~ s/^ *, *//;
      my @parameters = split / *, */, $parameters;
#     $parameters = join ' x ', @parameters;
 
      croak "No score defined" unless defined $score;
      croak "No valid score passed" unless $score->isa('Csound::Score');

      $score->f($gen_no, @parameters)->{table_nr};
    }gex;

    $orchestra_text .= $definition;
  }

# $orchestra_text .= "\n" if @{$self->{parameters}};

  $orchestra_text .= "\nendin\n";

  return $orchestra_text;

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
