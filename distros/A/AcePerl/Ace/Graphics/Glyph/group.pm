package Ace::Graphics::Glyph::group;
# a group of glyphs that move in a coordinated fashion
# currently they are always on the same vertical level (no bumping)

use strict;
use vars '@ISA';
use GD;
use Carp 'croak';

@ISA = 'Ace::Graphics::Glyph';

# override new() to accept an array ref for -feature
# the ref is not a set of features, but a set of other glyphs!
sub new {
  my $class = shift;
  my %arg = @_;
  my $parts = $arg{-feature};
  croak('Usage: Ace::Graphics::Glyph::group->new(-features=>$glypharrayref,-factory=>$factory)')
    unless ref $parts eq 'ARRAY';

  # sort parts horizontally
  my @sorted = sort { $a->left   <=> $b->left } @$parts;
  my $leftmost  = $sorted[0];
  my $rightmost = (sort { $a->right  <=> $b->right  } @$parts)[-1];

  my $self =  bless {
		     @_,
		     top      => 0,
		     left     => 0,
		     right    => 0,
		     leftmost => $leftmost,
		     rightmost => $rightmost,
		     members   => \@sorted,
		    },$class;


  @sorted = $self->bump;
  $self->{height} = $sorted[-1]->bottom - $sorted[0]->top;

  return $self;
}

sub members {
  my $self = shift;
  my $m = $self->{members} or return;
  return @$m;
}

sub move {
  my $self = shift;
  $self->SUPER::move(@_);
  $_->move(@_) foreach $self->members;
}

sub left  {  shift->{leftmost}->left   }
sub right {  shift->{rightmost}->right }

sub height {
  my $self = shift;
  $self->{height};
}

# this is replication of code in Track.pm;
# should have done a formal container/contained relationship
# in order to accomodate groups
sub bump {
  my $self = shift;
  my @glyphs = $self->members;

  my %occupied;
  for my $g (sort { $a->left <=> $b->left} @glyphs) {

    my $pos = 0;
    for my $y (sort {$a <=> $b} keys %occupied) {
      my $previous = $occupied{$y};
      last if $previous->right + 2 < $g->left;          # no collision at this position
      $pos += $previous->height + 2;                    # collision, so bump
    }
    $occupied{$pos} = $g;                           # remember where we are
    $g->move(0,$pos);
  }
  return sort { $a->top <=> $b->top } @glyphs;
}

# override draw method - draw individual subparts
sub draw {
  my $self = shift;
  my $gd = shift;
  my ($left,$top) = @_;

  # bail out if this isn't the right kind of feature
  my @parts = $self->members;

  # three pixels of black, three pixels of transparent
  my $black = 1;

  my ($x1,$y1,$x2,$y2) = $parts[0]->calculate_boundaries($left,$top);
  my $center1 = ($y2 + $y1)/2;

  $gd->setStyle($black,$black,gdTransparent,gdTransparent,);
  for (my $i=0;$i<@parts-1;$i++) {
    my ($x1,$y1,$x2,$y2) = $parts[$i]->calculate_boundaries($left,$top);
    my ($x3,$y3,$x4,$y4) = $parts[$i+1]->calculate_boundaries($left,$top);
    next unless ($x3 - $x1) >= 3;
    $gd->line($x2+1,($y1+$y2)/2,$x3-1,($y3+$y4)/2,gdStyled);
  }

}

1;

=head1 NAME

Ace::Graphics::Glyph::group - The group glyph

=head1 SYNOPSIS

none

=head1 DESCRIPTION

This is an internal glyph type, used by Ace::Graphics::Track for
moving sets of glyphs around as a group.  This glyph is created
automatically when processing a set of features passed to
Ace::Graphics::Panel->new as an array ref.

=head2 OPTIONS

In addition to the common options, the following glyph-specific
options are recognized:

  Option      Description               Default
  ------      -----------               -------

  -connect    Whether to connect members  false
              of the group by a dashed
              line.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<Ace::Sequence>, L<Ace::Sequence::Feature>, L<Ace::Graphics::Panel>,
L<Ace::Graphics::Track>, L<Ace::Graphics::Glyph::anchored_arrow>,
L<Ace::Graphics::Glyph::arrow>,
L<Ace::Graphics::Glyph::box>,
L<Ace::Graphics::Glyph::primers>,
L<Ace::Graphics::Glyph::segments>,
L<Ace::Graphics::Glyph::toomany>,
L<Ace::Graphics::Glyph::transcript>,

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
