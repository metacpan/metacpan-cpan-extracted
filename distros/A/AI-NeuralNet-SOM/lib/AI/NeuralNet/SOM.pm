package AI::NeuralNet::SOM;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use Data::Dumper;

=pod

=head1 NAME

AI::NeuralNet::SOM - Perl extension for Kohonen Maps

=head1 SYNOPSIS

  use AI::NeuralNet::SOM::Rect;
  my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
                                         input_dim  => 3);
  $nn->initialize;
  $nn->train (30, 
    [ 3, 2, 4 ], 
    [ -1, -1, -1 ],
    [ 0, 4, -3]);

  my @mes = $nn->train (30, ...);      # learn about the smallest errors
                                       # during training

  print $nn->as_data;                  # dump the raw data
  print $nn->as_string;                # prepare a somehow formatted string

  use AI::NeuralNet::SOM::Torus;
  # similar to above

  use AI::NeuralNet::SOM::Hexa;
  my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 6,
                                         input_dim  => 4);
  $nn->initialize ( [ 0, 0, 0, 0 ] );  # all get this value

  $nn->value (3, 2, [ 1, 1, 1, 1 ]);   # change value for a neuron
  print $nn->value (3, 2);

  $nn->label (3, 2, 'Danger');         # add a label to the neuron
  print $nn->label (3, 2);


=head1 DESCRIPTION

This package is a stripped down implementation of the Kohonen Maps
(self organizing maps). It is B<NOT> meant as demonstration or for use
together with some visualisation software. And while it is not (yet)
optimized for speed, some consideration has been given that it is not
overly slow.

Particular emphasis has been given that the package plays nicely with
others. So no use of files, no arcane dependencies, etc.

=head2 Scenario

The basic idea is that the neural network consists of a 2-dimensional
array of N-dimensional vectors. When the training is started these
vectors may be completely random, but over time the network learns
from the sample data, which is a set of N-dimensional vectors.

Slowly, the vectors in the network will try to approximate the sample
vectors fed in. If in the sample vectors there were clusters, then
these clusters will be neighbourhoods within the rectangle (or
whatever topology you are using).

Technically, you have reduced your dimension from N to 2.

=head1 INTERFACE

=head2 Constructor

The constructor takes arguments:

=over

=item C<input_dim> : (mandatory, no default)

A positive integer specifying the dimension of the sample vectors (and hence that of the vectors in
the grid).

=item C<learning_rate>: (optional, default C<0.1>)

This is a magic number which controls how strongly the vectors in the grid can be influenced. Stronger
movement can mean faster learning if the clusters are very pronounced. If not, then the movement is
like noise and the convergence is not good. To mediate that effect, the learning rate is reduced
over the iterations.

=item C<sigma0>: (optional, defaults to radius)

A non-negative number representing the start value for the learning radius. Practically, the value
should be chosen in such a way to cover a larger part of the map. During the learning process this
value will be narrowed down, so that the learning radius impacts less and less neurons.

B<NOTE>: Do not choose C<1> as the C<log> function is used on this value.

=back

Subclasses will (re)define some of these parameters and add others:

Example:

    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
				           input_dim  => 3);

=cut

sub new { die; }

=pod

=head2 Methods

=over

=item I<initialize>

I<$nn>->initialize

You need to initialize all vectors in the map before training. There are several options
how this is done:

=over

=item providing data vectors

If you provide a list of vectors, these will be used in turn to seed the neurons. If the list is
shorter than the number of neurons, the list will be started over. That way it is trivial to
zero everything:

  $nn->initialize ( [ 0, 0, 0 ] );

=item providing no data

Then all vectors will get randomized values (in the range [ -0.5 .. 0.5 ]).

=item using eigenvectors (see L</HOWTOS>)

=back

=item I<train>

I<$nn>->train ( I<$epochs>, I<@vectors> )

I<@mes> = I<$nn>->train ( I<$epochs>, I<@vectors> )

The training uses the list of sample vectors to make the network learn. Each vector is simply a
reference to an array of values.

The C<epoch> parameter controls how many vectors are processed. The vectors are B<NOT> used in
sequence, but picked randomly from the list. For this reason it is wise to run several epochs,
not just one. But within one epoch B<all> vectors are visited exactly once.

Example:

   $nn->train (30, 
               [ 3, 2, 4 ],
               [ -1, -1, -1 ], 
               [ 0, 4, -3]);

=cut

sub train {
    my $self   = shift;
    my $epochs = shift || 1;
    die "no data to learn" unless @_;

    $self->{LAMBDA} = $epochs / log ($self->{_Sigma0});                                 # educated guess?

    my @mes    = ();                                                                    # this will contain the errors during the epochs
    for my $epoch (1..$epochs)  {
	$self->{T} = $epoch;
	my $sigma = $self->{_Sigma0} * exp ( - $self->{T} / $self->{LAMBDA} );          # compute current radius
	my $l     = $self->{_L0}     * exp ( - $self->{T} / $epochs );                  # current learning rate

	my @veggies = @_;                                                               # make a local copy, that will be destroyed in the loop
	while (@veggies) {
	    my $sample = splice @veggies, int (rand (scalar @veggies) ), 1;             # find (and take out)

	    my @bmu = $self->bmu ($sample);                                             # find the best matching unit
	    push @mes, $bmu[2] if wantarray;
	    my $neighbors = $self->neighbors ($sigma, @bmu);                            # find its neighbors
	    map { _adjust ($self, $l, $sigma, $_, $sample) } @$neighbors;               # bend them like Beckham
	}
    }
    return @mes;
}

sub _adjust {                                                                           # http://www.ai-junkie.com/ann/som/som4.html
    my $self  = shift;
    my $l     = shift;                                                                  # the learning rate
    my $sigma = shift;                                                                  # the current radius
    my $unit  = shift;                                                                  # which unit to change
    my ($x, $y, $d) = @$unit;                                                           # it contains the distance
    my $v     = shift;                                                                  # the vector which makes the impact

    my $w     = $self->{map}->[$x]->[$y];                                               # find the data behind the unit
    my $theta = exp ( - ($d ** 2) / (2 * $sigma ** 2));                                 # gaussian impact (using distance and current radius)

    foreach my $i (0 .. $#$w) {                                                         # adjusting values
	$w->[$i] = $w->[$i] + $theta * $l * ( $v->[$i] - $w->[$i] );
    }
}

=pod

=item I<bmu>

(I<$x>, I<$y>, I<$distance>) = I<$nn>->bmu (I<$vector>)

This method finds the I<best matching unit>, i.e. that neuron which is closest to the vector passed
in. The method returns the coordinates and the actual distance.

=cut

sub bmu { die; }

=pod

=item I<mean_error>

I<$me> = I<$nn>->mean_error (I<@vectors>)

This method takes a number of vectors and produces the I<mean distance>, i.e. the average I<error>
which the SOM makes when finding the C<bmu>s for the vectors. At least one vector must be passed in.

Obviously, the longer you let your SOM be trained, the smaller the error should become.

=cut
    
sub mean_error {
    my $self = shift;
    my $error = 0;
    map { $error += $_ }                    # then add them all up
        map { ( $self->bmu($_) )[2] }       # then find the distance
           @_;                              # take all data vectors
    return ($error / scalar @_);            # return the mean value
}

=pod

=item I<neighbors>

I<$ns> = I<$nn>->neighbors (I<$sigma>, I<$x>, I<$y>)

Finds all neighbors of (X, Y) with a distance smaller than SIGMA. Returns a list reference of (X, Y,
distance) triples.

=cut

sub neighbors { die; }

=pod

=item I<output_dim> (read-only)

I<$dim> = I<$nn>->output_dim

Returns the output dimensions of the map as passed in at constructor time.

=cut

sub output_dim {
    my $self = shift;
    return $self->{output_dim};
}

=pod

=item I<radius> (read-only)

I<$radius> = I<$nn>->radius

Returns the I<radius> of the map. Different topologies interpret this differently.

=item I<map>

I<$m> = I<$nn>->map

This method returns a reference to the map data. See the appropriate subclass of the data
representation.

=cut

sub map {
    my $self = shift;
    return $self->{map};
}

=pod

=item I<value>

I<$val> = I<$nn>->value (I<$x>, I<$y>)

I<$nn>->value (I<$x>, I<$y>, I<$val>)

Set or get the current vector value for a particular neuron. The neuron is addressed via its
coordinates.

=cut

sub value {
    my $self    = shift;
    my ($x, $y) = (shift, shift);
    my $v       = shift;
    return defined $v ? $self->{map}->[$x]->[$y] = $v : $self->{map}->[$x]->[$y];
}

=pod

=item I<label>

I<$label> = I<$nn>->label (I<$x>, I<$y>)

I<$nn>->label (I<$x>, I<$y>, I<$label>)

Set or get the label for a particular neuron. The neuron is addressed via its coordinates.
The label can be anything, it is just attached to the position.

=cut

sub label {
    my $self    = shift;
    my ($x, $y) = (shift, shift);
    my $l       = shift;
    return defined $l ? $self->{labels}->[$x]->[$y] = $l : $self->{labels}->[$x]->[$y];
}

=pod

=item I<as_string>

print I<$nn>->as_string

This methods creates a pretty-print version of the current vectors.

=cut

sub as_string { die; }

=pod

=item I<as_data>

print I<$nn>->as_data

This methods creates a string containing the raw vector data, row by
row. This can be fed into gnuplot, for instance.

=cut

sub as_data { die; }

=pod

=back

=head1 HOWTOs

=over

=item I<using Eigenvectors to initialize the SOM>

See the example script in the directory C<examples> provided in the
distribution. It uses L<PDL> (for speed and scalability, but the
results are not as good as I had thought).

=item I<loading and saving a SOM>

See the example script in the directory C<examples>. It uses
C<Storable> to directly dump the data structure onto disk. Storage and
retrieval is quite fast.

=back

=head1 FAQs

=over

=item I<I get 'uninitialized value ...' warnings, many of them>

There is most likely something wrong with the C<input_dim> you
specified and your vectors should be having.

=back

=head1 TODOs

=over

=item maybe implement the SOM on top of PDL?

=item provide a ::SOM::Compat to have compatibility with the original AI::NeuralNet::SOM?

=item implement different window forms (bubble/gaussian), linear/random

=item implement the format mentioned in the original AI::NeuralNet::SOM

=item add methods as_html to individual topologies

=item add iterators through vector lists for I<initialize> and I<train>

=back

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker 
L<https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=AI-NeuralNet-SOM>

=head1 SEE ALSO

Explanation of the algorithm:

L<http://www.ai-junkie.com/ann/som/som1.html>

Old version of AI::NeuralNet::SOM from Alexander Voischev:

L<http://backpan.perl.org/authors/id/V/VO/VOISCHEV/>

Subclasses:

L<AI::NeuralNet::Hexa>
L<AI::NeuralNet::Rect>
L<AI::NeuralNet::Torus>


=head1 AUTHOR

Robert Barta, E<lt>rho@devc.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 200[78] by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION = '0.07';

1;

__END__


sub bmu {
    my $self = shift;
    my $sample = shift;

    my $closest;                                                               # [x,y, distance] value and co-ords of closest match
    foreach my $coor ($self->_get_coordinates) {                               # generate all coord pairs, not overly happy with that
	my ($x, $y) = @$coor;
	my $distance = _vector_distance ($self->{map}->[$x]->[$y], $sample);   # || Vi - Sample ||
	$closest = [0,  0,  $distance] unless $closest;
	$closest = [$x, $y, $distance] if $distance < $closest->[2];
    }
    return @$closest;
}

