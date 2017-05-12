package AI::NeuralNet::FastSOM::Rect;

use strict;
use warnings;

use AI::NeuralNet::FastSOM;
our @ISA = qw/AI::NeuralNet::FastSOM/;

our $VERSION = '0.19';

sub _old_radius { shift->{_R} }

sub initialize {
    my $self = shift;
    my @data = @_;

    my $i = 0;

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

sub as_string {
    my $self = shift;
    my $s = '';

    $s .= "    ";
    for my $y (0 .. $self->{_Y}-1){
        $s .= sprintf("   %02d ",$y);
    }
    $s .= "\n" . "-"x107 . "\n";

    my $dim = scalar @{ $self->{map}->[0]->[0] };

    for my $x (0 .. $self->{_X}-1) {
        for my $w ( 0 .. $dim-1 ){
            $s .= sprintf("%02d | ",$x);
            for my $y (0 .. $self->{_Y}-1){
                $s .= sprintf("% 2.2f ", $self->{map}->[$x]->[$y]->[$w]);
            }
            $s .= "\n";
        }
        $s .= "\n";
    }
    return $s;
}

sub as_data {
    my $self = shift;
    my $s = '';

    my $dim = scalar @{ $self->{map}->[0]->[0] };
    for my $x (0 .. $self->{_X}-1) {
        for my $y (0 .. $self->{_Y}-1){
            for my $w ( 0 .. $dim-1 ){
                $s .= sprintf("\t%f", $self->{map}->[$x]->[$y]->[$w]);
            }
            $s .= "\n";
        }
    }
    return $s;
}

1;

__END__

=pod

=head1 NAME

AI::NeuralNet::FastSOM::Rect - Perl extension for Kohonen Maps (rectangular topology)

=head1 SYNOPSIS

  use AI::NeuralNet::FastSOM::Rect;
  my $nn = new AI::NeuralNet::FastSOM::Rect (output_dim => "5x6",
                                         input_dim  => 3);
  $nn->initialize;
  $nn->train (30, 
    [ 3, 2, 4 ], 
    [ -1, -1, -1 ],
    [ 0, 4, -3]);

  print $nn->as_data;

=head1 INTERFACE

=head2 Constructor

The constructor takes the following arguments (additionally to those in
the base class):

=over

=item C<output_dim> : (mandatory, no default)

A string of the form "3x4" defining the X and the Y dimensions.

=back

Example:

    my $nn = new AI::NeuralNet::FastSOM::Rect (output_dim => "5x6",
                                           input_dim  => 3);

=head2 Methods

=over

=item I<map>

I<$m> = I<$nn>->map

This method returns the 2-dimensional array of vectors in the grid
(as a reference to an array of references to arrays of vectors). The
representation of the 2-dimensional array is straightforward.

Example:

   my $m = $nn->map;
   for my $x (0 .. 5) {
       for my $y (0 .. 4){
           warn "vector at $x, $y: ". Dumper $m->[$x]->[$y];
       }
   }

=item I<as_data>

print I<$nn>->as_data

This methods creates a string containing the raw vector data, row by
row. This can be fed into gnuplot, for instance.

=back

=head1 SEE ALSO

L<http://www.ai-junkie.com/ann/som/som1.html>

=head1 AUTHOR

Rick Myers, E<lt>jrm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by Rick Myers

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

