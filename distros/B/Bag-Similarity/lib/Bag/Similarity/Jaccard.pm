package Bag::Similarity::Jaccard;

use strict;
use warnings;

use parent 'Bag::Similarity';
use Bag::Similarity::Dice;

our $VERSION = '0.022';

sub from_bags {
  my ($self, $set1, $set2) = @_;

  my $intersection = $self->intersection($set1,$set2);
  my $union = $self->combined_length($set1,$set2) - $intersection;
  # ( A intersect B ) / (A union B)
  return ($intersection / $union);
}



1;


__END__

=head1 NAME

Bag::Similarity::Jaccard - Jaccard similarity for bags

=head1 SYNOPSIS

 use Bag::Similarity::Jaccard;
 
 # object method
 my $jaccard = Bag::Similarity::Jaccard->new;
 my $similarity = $jaccard->similarity('Photographer','Fotograf');
 
 
=head1 DESCRIPTION

=head2 Jaccard similarity

 $dice / (2 - $dice)
 
or

 ( A intersect B ) / (A union B)
 

=head1 METHODS

L<Bag::Similarity::Jaccard> inherits all methods from L<Bag::Similarity> and implements the
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

