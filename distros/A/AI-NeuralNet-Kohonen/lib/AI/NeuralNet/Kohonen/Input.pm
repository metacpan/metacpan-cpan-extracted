package AI::NeuralNet::Kohonen::Input;

use vars qw/$VERSION $TRACE/;
$VERSION = 0.1;
$TRACE = 1;

=head1 NAME

AI::NeuralNet::Kohonen::Input - an input vector for AI::NeuralNet::Kohonen

=head1 DESCRIPTION

Implimentation of an input vector for the Kohonen SOM:
L<AI::NeuralNet::Kohonen>.

=cut

use strict;
use warnings;
use Carp qw/cluck carp confess croak/;

=head1 CONSTRUCTOR (new)

=over 4

=item dim

Scalar - the number of dimensions of this input vector.
Need not be supplied if C<values> is supplied.

=item values

Reference to an array containing the values for this
input vector. There should be one entry for each dimension,
with unknown values having the value C<undef>.

=item class

Optional class label string for this input vector.

=back

=cut

sub new {
	my $class	= shift;
	my %args	= @_;
	my $self 	= bless \%args,$class;
	if (not defined $self->{values}){
		if (not defined $self->{dim}){
			cluck "No {dim} or {weight}!";
			return undef;
		}
		$self->{values} = [];
	} elsif (not ref $self->{values}){
		cluck "{values} not supplied!";
		return undef;
	} elsif (ref $self->{values} ne 'ARRAY') {
		cluck "{values} should be an array reference, not $self->{values}!";
		return undef;
	} elsif (defined $self->{dim} and defined $self->{values}
			and $self->{dim} ne $#{$self->{values}}){
		cluck "{values} and {dim} do not match!";
		return undef;
	} else {
		$self->{dim} = $#{$self->{values}};
	}
	return $self;
}



1;

__END__

=head1 SEE ALSO

The L<AI::NeuralNet::Kohonen>.

=head1 AUTHOR AND COYRIGHT

This implimentation Copyright (C) Lee Goddard, 2003.
All Rights Reserved.

Available under the same terms as Perl itself.
















