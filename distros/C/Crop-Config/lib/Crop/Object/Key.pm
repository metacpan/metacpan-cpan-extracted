package Crop::Object::Key;
use base qw/ Crop /;

=begin nd
Class: Crop::Object::Key
	Key of an Object.
	
	This module not inherit <Crop::Object>, so automatic generation of getters/setters missed.
	
	<my %Attibutes> are default values each item has.
=cut

use v5.14;
use warnings;

=begin nd
Variable: my %Attributes
	Attributes:

	type - 'counter' for Sequence.n, 'ordinal' for Simple, 'extern' for Sequence exernal id
=cut
my %Attributes = (
	type => undef,
);

=begin nd
Constructor: new (%in)
	Set the type of key.

Parameters:
	%in - one item 'type' has predefined vaule
	
Returns:
	$self
=cut
sub new {
	my ($class, %in) = @_;

	my $self = bless {
		%Attributes,
		%in,
	}, $class;
}

=begin nd
Method: type ( )
	Getter.
	
Returns:
	type of key
=cut
sub type { shift->{type} }

1;
