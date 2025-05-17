package Crop::Refbook;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Refbook
	Global refbook.
	
	Refbook contains a lot of global unrelated values used
	arround the entire code.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util qw/ load_class /;
use Crop::Prop::Value;
use Crop::Prop::Type;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	code        - code to perl use
	description - description
	id          - <Crop::Object::Simple> descendant
	id_prop     - appropriate <Crop::Prop>
	id_val      - real value
	name        - name
	val         - <Crop::Prop::Value> corresponding id_val attribute
=cut
our %Attributes = (
	code        => undef,
	description => undef,
	id_prop     => undef,
	id_val      => undef,
	name        => undef,
	val         => {type => 'cache'},
);

=begin nd
Method: is_gt ($rhs)
	Is Refbook value greater than $val?
	
Parameters:
	$rhs - RHS
	
Returns:
	true - if Refbook is greater
	false - oterhwise
=cut
sub is_gt {
	my ($self, $rhs) = @_;
	
	$self->{val} = Crop::Prop::Value->Get($self->{id}) unless $self->{val};

	my $proptype = Crop::Prop::Type->Get($self->{val}->id_proptype);

	$proptype->is_gt($self->{val}, $rhs);
}

=begin nd
Method: Table ( )
	Table in the Warehouse.

Returns:
	'refbook' string
=cut
sub Table { 'refbook' }

1;
