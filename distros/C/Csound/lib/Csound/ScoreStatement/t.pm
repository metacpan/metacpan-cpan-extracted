#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound::ScoreStatement

L<http://www.csounds.com/manual/html/ScoregensTop.html>

=cut
#_}

package Csound::ScoreStatement::t;

use warnings;
use strict;
use 5.10.0; # state

use Carp;

use Csound::ScoreStatement;

our $VERSION = $Csound::VERSION;
our @ISA     = qw(Csound::ScoreStatement);

#_{ Synopsis

=head1 SYNOPSIS

    use Csound::ScoreStatement::t;

    my $t = Csound::ScoreStatement::t->new();

    $t->tempo($t, $beats_per_minute);

=cut
#_}
#_{ Description
=head DESCRIPTION

The C<t> statement controls the tempo of a L<< score's|Csound::Score >> beats.

The syntax is

    t 0 tempo-0 t-1 tempo-1 t-2 tempo-2 t-3 tempo-3 …

where C<t-n> is the number of a beat and C<tempo-n> is the tempo in beats per minute at that given beat.

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

    my $t = Csound::ScoreStatement::t->new($start_tempo);

=cut
#_}

  my $class       = shift;
  my $self        = {};
  my $start_tempo = shift;

  bless $self, $class;
  die unless $self->isa('Csound::ScoreStatement::t');


  $self->{tempi} = [];

  $self->tempo(0, $start_tempo);

  return $self;

} #_}
sub tempo { #_{
#_{ POD
=head2 new

    $t->tempo($t, $beats_per_minute);

=cut
#_}

  my $self = shift;
  die unless $self->isa('Csound::ScoreStatement::t');

  my $t     = shift;
  my $tempo = shift;

  push @{$self->{tempi}}, [$t, $tempo];

} #_}
sub score_text { #_{
#_{ POD
=head2 new

    my $score_text = $t->score_text;

Return the text to be written into the L<< score|Csound::Score >>.

=cut
#_}

  my $self = shift;
  die unless $self->isa('Csound::ScoreStatement::t');

  my $ret = "t";

  for my $t (@{$self->{tempi}}) {
    $ret .= " $t->[0] $t->[1]";
  }

  return $ret;


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
