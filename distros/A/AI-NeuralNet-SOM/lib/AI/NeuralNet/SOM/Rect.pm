package AI::NeuralNet::SOM::Rect;

use strict;
use warnings;

use Data::Dumper;
use base qw(AI::NeuralNet::SOM);
use AI::NeuralNet::SOM::Utils;

=pod

=head1 NAME

AI::NeuralNet::SOM::Rect - Perl extension for Kohonen Maps (rectangular topology)

=head1 SYNOPSIS

  use AI::NeuralNet::SOM::Rect;
  my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
                                         input_dim  => 3);
  $nn->initialize;
  $nn->train (30, 
    [ 3, 2, 4 ], 
    [ -1, -1, -1 ],
    [ 0, 4, -3]);

  print $nn->as_data;

=head1 INTERFACE

=head2 Constructor

The constructor takes the following arguments (additionally to those in the base class):

=over

=item C<output_dim> : (mandatory, no default)

A string of the form "3x4" defining the X and the Y dimensions.

=back

Example:

    my $nn = new AI::NeuralNet::SOM::Rect (output_dim => "5x6",
                                           input_dim  => 3);

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless { %options }, $class;

    if ($self->{output_dim} =~ /(\d+)x(\d+)/) {
	$self->{_X} = $1 and $self->{_Y} = $2;
    } else {
	die "output dimension does not have format MxN";
    }
    if ($self->{input_dim} > 0) {
	$self->{_Z} = $self->{input_dim};
    } else {
	die "input dimension must be positive integer";
    }


    ($self->{_R}) = map { $_ / 2 } sort {$b <= $a } ($self->{_X}, $self->{_Y});          # radius
    $self->{_Sigma0} = $options{sigma0} || $self->{_R};                                  # impact distance, start value
    $self->{_L0} = $options{learning_rate} || 0.1;                                       # learning rate, start value
    return $self;
}

=pod

=head2 Methods

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

    for my $x (0 .. $self->{_X}-1) {
	for my $y (0 .. $self->{_Y}-1) {
	    $self->{map}->[$x]->[$y] = &$get_from_stream;
	}
    }
}

sub bmu {
    my $self = shift;
    my $sample = shift;

    my $closest;                                                               # [x,y, distance] value and co-ords of closest match
    for my $x (0 .. $self->{_X}-1) {
        for my $y (0 .. $self->{_Y}-1){
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
    for my $x (0 .. $self->{_X}-1) {
        for my $y (0 .. $self->{_Y}-1){
            my $distance = sqrt ( ($x - $X) * ($x - $X) + ($y - $Y) * ($y - $Y) );
	    next if $distance > $sigma;
	    push @neighbors, [ $x, $y, $distance ];                                    # we keep the distances
	}
    }
    return \@neighbors;
}

=pod

=cut

sub radius {
    my $self = shift;
    return $self->{_R};
}

=pod

=over

=item I<map>

I<$m> = I<$nn>->map

This method returns the 2-dimensional array of vectors in the grid (as a reference to an array of
references to arrays of vectors). The representation of the 2-dimensional array is straightforward.

Example:

   my $m = $nn->map;
   for my $x (0 .. 5) {
       for my $y (0 .. 4){
           warn "vector at $x, $y: ". Dumper $m->[$x]->[$y];
       }
   }

=cut

sub as_string {
    my $self = shift;
    my $s = '';

    $s .= "    ";
    for my $y (0 .. $self->{_Y}-1){
	$s .= sprintf ("   %02d ",$y);
    }
    $s .= sprintf "\n","-"x107,"\n";
    
    my $dim = scalar @{ $self->{map}->[0]->[0] };
    
    for my $x (0 .. $self->{_X}-1) {
	for my $w ( 0 .. $dim-1 ){
	    $s .= sprintf ("%02d | ",$x);
	    for my $y (0 .. $self->{_Y}-1){
		$s .= sprintf ("% 2.2f ", $self->{map}->[$x]->[$y]->[$w]);
	    }
	    $s .= sprintf "\n";
	}
	$s .= sprintf "\n";
    }
    return $s;
}

=pod

=item I<as_data>

print I<$nn>->as_data

This methods creates a string containing the raw vector data, row by
row. This can be fed into gnuplot, for instance.

=cut

sub as_data {
    my $self = shift;
    my $s = '';

    my $dim = scalar @{ $self->{map}->[0]->[0] };
    for my $x (0 .. $self->{_X}-1) {
	for my $y (0 .. $self->{_Y}-1){
	    for my $w ( 0 .. $dim-1 ){
		$s .= sprintf ("\t%f", $self->{map}->[$x]->[$y]->[$w]);
	    }
	    $s .= sprintf "\n";
	}
    }
    return $s;
}

=pod

=back


=head1 SEE ALSO

L<http://www.ai-junkie.com/ann/som/som1.html>

=head1 AUTHOR

Robert Barta, E<lt>rho@devc.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Robert Barta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

our $VERSION = '0.02';

1;

__END__


