package Crop::Object::Sequence;
use base qw / Crop::Object /;

=begin nd
Class: Crop::Object::Sequence
	Primary key includes the 'n' attribute.
	
	IMPORTANT: the %Attributes of derived class MUST setup the 'key'
	> id_obj => {key => 'extern'}
	or SELECT will give incomplete results!
	
	'n' is a counter inside other part of a primary key. It starts from '1' and must be continious, whithout missing elements.
	The 'n' defines sorting order.

	As the other keys, 'n' has the 'key' element in their declaration
	> our %Attributes = (
	>   n => {key => 'counter'},
	>);
=cut

use v5.14;
use warnings;

use Crop::Object::Constants;
use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	n - counter inside primary key
=cut
our %Attributes = (
	n => {mode => 'read', type => 'key', key => 'counter'},
);

=begin nd
Method: _Prepare_key ( )
	Generate 'n'.
	
	An error will arised though only one 'extern' key is missed.

Returns:
	n     - actual vaule; always is true
	undef - one of the 'extern' key is missed
=cut
sub _Prepare_key {
	my $self = shift;

	my $table = $self->Table or return warn "OBJECT|ERR: Can't generate primary key because of missing table.";

	my %key;
	my $counter;
	my $attrs = $self->Attributes(KEY);
	for (@$attrs) {
		my $val = $self->{$_->name};
		
		if ($_->key->type eq 'counter') {
			$counter = $val;
		} else {
			return unless $val;
			
			$key{$_->name} = $val;
		}
	}
	return $counter if $counter;
	
	my $last = $self->All(%key, SORT => 'n desc')->First;
	$self->{n} = $last ? $last->n + 1 : 1;  # returns n >= 1; true
}

=begin nd
Method: Table ( )
	Table storage in the Warehouse.

	This method must be redefined by subclass.

Returns:
	undef - and the error will arised
=cut
sub Table { return warn "OBJECT|ERR: The Table method should be redefined by subclass"; }

1;
