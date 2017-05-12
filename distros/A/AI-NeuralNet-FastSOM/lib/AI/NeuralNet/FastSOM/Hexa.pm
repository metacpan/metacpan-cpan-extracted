package AI::NeuralNet::FastSOM::Hexa;

use strict;
use warnings;

use AI::NeuralNet::FastSOM;
our @ISA = qw/AI::NeuralNet::FastSOM/;

our $VERSION = '0.19';

sub radius   { shift->{_R} }
sub diameter { shift->{_X} }

sub as_data   { die 'not implemented' }
sub as_string { die 'not implemented' }

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
        for my $y (0 .. $self->{_X}-1) {
            $self->{map}->[$x]->[$y] = &$get_from_stream;
        }
    }
}

1;

__END__

=pod

=head1 NAME

AI::NeuralNet::FastSOM::Hexa - Perl extension for Kohonen Maps (hexagonal topology)

=head1 SYNOPSIS

  use AI::NeuralNet::FastSOM::Hexa;
  my $nn = new AI::NeuralNet::FastSOM::Hexa (output_dim => 6,
                                         input_dim  => 3);
  # ... see also base class AI::NeuralNet::FastSOM

=head1 INTERFACE

=head2 Constructor

The constructor takes the following arguments (additionally to those in
the base class):

=over

=item C<output_dim> : (mandatory, no default)

A positive, non-zero number specifying the diameter of the hexagonal. C<1>
creates one with a single hexagon, C<2> one with 4, C<3> one with 9. The
number plays the role of a diameter.

=back

Example:

    my $nn = new AI::NeuralNet::FastSOM::Hexa (output_dim => 6,
                                           input_dim  => 3);

=head2 Methods

=over

=item I<radius>

Returns the radius (half the diameter).

=item I<diameter>

Returns the diameter (= dimension) of the hexagon.

=item I<map>

I<$m> = I<$nn>->map

This method returns the 2-dimensional array of vectors in the grid
(as a reference to an array of references to arrays of vectors).

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

=item I<as_data>

Not implemented.

=back

=head1 AUTHOR

Rick Myers, E<lt>jrm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by Rick Myers

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

sub _get_coordinates {
    my $self = shift;
    my $D1 = $self->{_D}-1;
    my $t;
    return map { $t = $_ ; map { [ $t, $_ ] } (0 .. $D1) } (0 .. $D1)
}

sqrt ( ($x - $X) ** 2 + ($y - $Y) ** 2 );

