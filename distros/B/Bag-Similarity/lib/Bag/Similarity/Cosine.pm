package Bag::Similarity::Cosine;

use strict;
use warnings;

use parent 'Bag::Similarity';

our $VERSION = '0.021';

sub from_bags {
  my ($self, $bag1, $bag2) = @_;

  my $cosine = $self->_cosine(
    $self->_normalize($self->_make_vector( $bag1 )),
    $self->_normalize($self->_make_vector( $bag2 ))
  );
  return $cosine;
}

sub _make_vector {
  my ( $self, $tokens ) = @_;
  my %elements;
  do { $_++ } for @elements{@$tokens};
  return \%elements;
}

# Assumes both incoming vectors are normalized
sub _cosine { shift->_dot( @_ ) }

sub _norm {
  my $self = shift;
  my $vector = shift;
  my $sum = 0;
  for my $key (keys %$vector) {
    $sum += $vector->{$key} ** 2;
  }
  return sqrt $sum;
}

sub _normalize {
  my $self = shift;
  my $vector = shift;

  return $self->_div(
    $vector,
    $self->_norm($vector)
  );
}

sub _dot {
  my $self = shift;
  my $vector1 = shift;
  my $vector2 = shift;

  my $dotprod = 0;

  for my $key (keys %$vector1) {
    $dotprod += $vector1->{$key} * $vector2->{$key} if ($vector2->{$key});
  }
  return $dotprod;
}


# divides each vector entry by a given divisor
sub _div {
  my $self = shift;
  my $vector = shift;
  my $divisor = shift;

  my $vector2 =  {};
  for my $key (keys %$vector) {
    $vector2->{$key} = $vector->{$key} / $divisor;
  }
  return $vector2;
}


1;


__END__

=head1 NAME

Bag::Similarity::Cosine - Cosine similarity for sets

=head1 SYNOPSIS

 use Bag::Similarity::Cosine;

 # object method
 my $cosine = Bag::Similarity::Cosine->new;
 my $similarity = $cosine->similarity('Photographer','Fotograf');


=head1 DESCRIPTION

=head2 Cosine similarity

A intersection B / (sqrt(A) * sqrt(B))


=head1 METHODS

L<Bag::Similarity::Cosine> inherits all methods from L<Bag::Similarity> and implements the
following new ones.

=head2 from_bags

  my $similarity = $object->from_bags(['a'],['b']);

This method expects two arrayrefs of strings as parameters. The parameters are not checked, thus can lead to funny results or uncatched divisions by zero.

If you want to use this method directly, you should catch the situation where one of the arrayrefs is empty (similarity is 0), or both are empty (similarity is 1).

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Bag-Similarity>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

