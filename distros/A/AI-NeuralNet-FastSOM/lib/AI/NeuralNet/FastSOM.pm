package AI::NeuralNet::FastSOM;

use strict;
use warnings;
use XSLoader;

our $VERSION = '0.19';

sub new { die 'Dont use this class directly' }

sub label {
	my ($self, $x, $y, $l) = @_;
	return defined $l
		? $self->{labels}->[$x]->[$y] = $l
		: $self->{labels}->[$x]->[$y];
}

sub value {
	my ($self, $x, $y, $v) = @_;
	return defined $v
		? $self->{map}[$x][$y] = $v
		: $self->{map}[$x][$y];
}

sub mean_error {
    my $self = shift;
    my $error = 0;
    map { $error += $_ }                    # then add them all up
        map { ( $self->bmu($_) )[2] }       # then find the distance
           @_;                              # take all data vectors
    return ($error / scalar @_);            # return the mean value
}

XSLoader::load(__PACKAGE__);

1;

__END__

=pod

=head1 NAME

AI::NeuralNet::FastSOM - Perl extension for fast Kohonen Maps

=head1 SYNOPSIS

  use AI::NeuralNet::FastSOM::Rect;

instead of

  use AI::NeuralNet::SOM;

=head1 DESCRIPTION

A drop-in replacement for Robert Barta's AI::NeuralNet::SOM. See those
docs for details.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker 

=head1 SEE ALSO

Explanation of the algorithm:

L<http://www.ai-junkie.com/ann/som/som1.html>

Subclasses:

L<AI::NeuralNet::FastSOM::Hexa>
L<AI::NeuralNet::FastSOM::Rect>
L<AI::NeuralNet::FastSOM::Torus>


=head1 AUTHOR

Rick Myers, E<lt>jrm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by Rick Myers

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

