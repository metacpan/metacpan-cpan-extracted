package AI::NeuralNet::SOM::Hexa;

use strict;
use warnings;

use AI::NeuralNet::SOM;
use Data::Dumper;
use base qw(AI::NeuralNet::SOM);

use AI::NeuralNet::SOM::Utils;

=pod

=head1 NAME

AI::NeuralNet::SOM::Hexa - Perl extension for Kohonen Maps (hexagonal topology)

=head1 SYNOPSIS

  use AI::NeuralNet::SOM::Hexa;
  my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 6,
                                         input_dim  => 3);
  # ... see also base class AI::NeuralNet::SOM

=head1 INTERFACE

=head2 Constructor

The constructor takes the following arguments (additionally to those in the base class):

=over

=item C<output_dim> : (mandatory, no default)

A positive, non-zero number specifying the diameter of the hexagonal. C<1> creates one with a single
hexagon, C<2> one with 4, C<3> one with 9. The number plays the role of a diameter.

=back

Example:

    my $nn = new AI::NeuralNet::SOM::Hexa (output_dim => 6,
                                           input_dim  => 3);

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless { %options }, $class;

    if ($self->{output_dim} > 0) {
	$self->{_D} = $self->{output_dim};
    } else {
	die "output dimension must be positive integer";
    }
    if ($self->{input_dim} > 0) {
	$self->{_Z} = $self->{input_dim};
    } else {
	die "input dimension must be positive integer";
    }

    $self->{_R}      = $self->{_D} / 2;
    $self->{_Sigma0} = $options{sigma0}        || $self->{_R};                                  # impact distance, start value
    $self->{_L0}     = $options{learning_rate} || 0.1;                                       # learning rate, start value

    return $self;
}

=pod

=head2 Methods

=over

=item I<radius>

Returns the radius (half the diameter).

=cut

sub radius {
    my $self = shift;
    return $self->{_R};
}

=pod

=item I<diameter>

Returns the diameter (= dimension) of the hexagon.

=cut

sub diameter {
    my $self = shift;
    return $self->{_D};
}

=pod

=cut

sub initialize {
    my $self = shift;
    my @data = @_;

    our $i = 0;
    my $get_from_stream = sub {
	$i = 0 if $i > $#data;
	return [ @{ $data[$i++] } ];  # cloning !
    } if @data;
    $get_from_stream ||= sub {
	return [ map { rand( 1 ) - 0.5 } 1..$self->{_Z} ];
    };

    for my $x (0 .. $self->{_D}-1) {
	for my $y (0 .. $self->{_D}-1) {
	    $self->{map}->[$x]->[$y] = &$get_from_stream;
	}
    }
}

sub bmu {
    my $self = shift;
    my $sample = shift;

    my $closest;                                                               # [x,y, distance] value and co-ords of closest match
    for my $x (0 .. $self->{_D}-1) {
        for my $y (0 .. $self->{_D}-1){
	    my $distance = AI::NeuralNet::SOM::Utils::vector_distance ($self->{map}->[$x]->[$y], $sample);   # || Vi - Sample ||
#warn "distance to $x, $y : $distance";
	    $closest = [0,  0,  $distance] unless $closest;
	    $closest = [$x, $y, $distance] if $distance < $closest->[2];
	}
    }
    return @$closest;
}

sub neighbors {                                                               # http://www.ai-junkie.com/ann/som/som3.html
    my $self = shift;
    my $sigma = shift;
    my $X     = shift;
    my $Y     = shift;     

    my @neighbors;
    for my $x (0 .. $self->{_D}-1) {
        for my $y (0 .. $self->{_D}-1){
            my $distance = _hexa_distance ($X, $Y, $x, $y);
##warn "$X, $Y, $x, $y: distance: $distance";
	    next if $distance > $sigma;
	    push @neighbors, [ $x, $y, $distance ];                                    # we keep the distances
	}
    }
    return \@neighbors;
}

sub _hexa_distance {
    my ($x1, $y1) = (shift, shift);   # one point
    my ($x2, $y2) = (shift, shift);   # another

    ($x1, $y1, $x2, $y2) = ($x2, $y2, $x1, $y1)  # swapping
	if ( $x1+$y1 > $x2+$y2 );

    my $dx = $x2 - $x1;
    my $dy = $y2 - $y1;

    if ($dx < 0 || $dy < 0) {
	return abs ($dx) + abs ($dy);
    } else {
	return $dx < $dy ? $dy : $dx;
    }
}

=pod

=item I<map>

I<$m> = I<$nn>->map

This method returns the 2-dimensional array of vectors in the grid (as a reference to an array of
references to arrays of vectors).

Example:

   my $m = $nn->map;
   for my $x (0 .. $nn->diameter -1) {
       for my $y (0 .. $nn->diameter -1){
           warn "vector at $x, $y: ". Dumper $m->[$x]->[$y];
       }
   }

This array represents a hexagon like this (ASCII drawing is so cool):

               <0,0>
           <0,1>   <1,0>
       <0,2>   <1,1>   <2,0>
   <0,3>   <1,2>   <2,1>   <3,0>
  ...............................


=item I<as_string>

Not implemented.

=cut

## TODO: pretty printing of this as hexagon ?
sub as_string { die "not implemented"; }

=pod

=item I<as_data>

Not implemented.

=cut

sub as_data { die "not implemented"; }

=pod

=back

=head1 AUTHOR

Robert Barta, E<lt>rho@devc.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 200[78] by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION = '0.02';

1;

__END__



sub _get_coordinates {
    my $self = shift;
    my $D1 = $self->{_D}-1;
    my $t;
    return map { $t = $_ ; map { [ $t, $_ ] } (0 .. $D1) } (0 .. $D1)
}

sqrt ( ($x - $X) ** 2 + ($y - $Y) ** 2 );
