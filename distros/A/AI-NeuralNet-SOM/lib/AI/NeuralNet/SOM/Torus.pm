package AI::NeuralNet::SOM::Torus;

use strict;
use warnings;

use Data::Dumper;
use base qw(AI::NeuralNet::SOM::Rect);
use AI::NeuralNet::SOM::Utils;

=pod

=head1 NAME

AI::NeuralNet::SOM::Torus - Perl extension for Kohonen Maps (torus topology)

=head1 SYNOPSIS

  use AI::NeuralNet::SOM::Torus;
  my $nn = new AI::NeuralNet::SOM::Torus (output_dim => "5x6",
                                          input_dim  => 3);
  $nn->initialize;
  $nn->train (30, 
    [ 3, 2, 4 ], 
    [ -1, -1, -1 ],
    [ 0, 4, -3]);

  print $nn->as_data;

=head1 DESCRIPTION

This SOM is very similar to that with a rectangular topology, except that the rectangle is connected
on the top edge and the bottom edge to first form a cylinder; and that cylinder is then formed into
a torus by connecting the rectangle's left and right border (L<http://en.wikipedia.org/wiki/Torus>).

=head1 INTERFACE

It exposes the same interface as the base class.

=cut

sub neighbors {                                                               # http://www.ai-junkie.com/ann/som/som3.html
    my $self   = shift;
    my $sigma  = shift;
    my $sigma2 = $sigma * $sigma;          # need the square more often
    my $X      = shift;
    my $Y      = shift;

    my ($_X, $_Y) = ($self->{_X}, $self->{_Y});

    my @neighbors;
    for my $x (0 .. $self->{_X}-1) {
        for my $y (0 .. $self->{_Y}-1){                                                                # this is not overly elegant, or fast
	    my $distance2 = ($x       - $X) * ($x       - $X) + ($y       - $Y) * ($y       - $Y);     # take the node with its x,y coords
	    push @neighbors, [ $x, $y, sqrt($distance2) ] if $distance2 <= $sigma2;

	       $distance2 = ($x - $_X - $X) * ($x - $_X - $X) + ($y       - $Y) * ($y       - $Y);     # take the node transposed to left by _X
	    push @neighbors, [ $x, $y, sqrt ($distance2) ] if $distance2 <= $sigma2;

	       $distance2 = ($x + $_X - $X) * ($x + $_X - $X) + ($y       - $Y) * ($y       - $Y);     # transposed by _X to right
	    push @neighbors, [ $x, $y, sqrt ($distance2) ] if $distance2 <= $sigma2;

	       $distance2 = ($x       - $X) * ($x       - $X) + ($y - $_Y - $Y) * ($y - $_Y - $Y);     # same with _Y up
	    push @neighbors, [ $x, $y, sqrt ($distance2) ] if $distance2 <= $sigma2;

	       $distance2 = ($x       - $X) * ($x       - $X) + ($y + $_Y - $Y) * ($y + $_Y - $Y);     # and down
	    push @neighbors, [ $x, $y, sqrt ($distance2) ] if $distance2 <= $sigma2;
	}
    }
    return \@neighbors;
}

=pod

=head1 SEE ALSO

L<AI::NeuralNet::SOM::Rect>

=head1 AUTHOR

Robert Barta, E<lt>rho@devc.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION = '0.01';

1;

__END__


