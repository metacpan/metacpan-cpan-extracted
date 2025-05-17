package Crop::Prop::Type;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Prop::Type
	Property type.
	
	Abstract class.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util qw/ expose_hashes load_class /;

=begin nd
Variable: our %Attributes
	Class attributes:

	code        - reference to subclass
	description - description
	id          - from <Crop::Object::Simple>
	name        - name
=cut
our %Attributes = (
	code        => {mode => 'read'},
	description => undef,
	name        => undef,
);

=begin nd
Constructor: new (@attr)
	Fabrica of subclasses.
	
	Based on code.
	
Parameters:
	@attr - attributes
	
Returns:
	$self - on success
	undef - error
=cut
sub new {
	my ($class, @attr) = @_;
	my $attr = expose_hashes \@attr; 
	
	if ($class eq __PACKAGE__) {
		return warn "OBJECT|CRIT: " . __PACKAGE__ . ' cannot init without the code attribute' unless exists $attr->{code};
		
		my $worker = __PACKAGE__ . "::$attr->{code}";
		load_class $worker or return warn "Cannot init Property Type as $worker failure";
		
		$worker->new(@attr);
	} else {
		$class->SUPER::new(@attr);
	}
}

=begin nd
Method: is_gt ($val, $rhs)
	Is greater $val over $rhs?
	
	Pure virtual.
	
Parameters:
	$val - LHS of <Crop:Prop::Value>
	$rhs - RHS in bytes
	
Returns:
	error
=cut
sub is_gt {
	my $either = shift;
	my $class = ref $either // $either;
	
	warn "OBJECT|CRIT: Method is_gt() must be redefined by subclass $class";
}

=begin nd
Method: Table ( )
	Table in the Warehouse.

Returns:
	'proptype' string
=cut
sub Table { 'proptype' }

1;
