package Crop::Prop::Type::MEMORY;
use base qw/ Crop::Prop::Type /;

=begin nd
Class: Crop::Prop::Type::MEMORY
	Property type MEMORY.
	
	Default RHS units are bytes.
=cut

use v5.14;
use warnings;

=begin nd
Constants:
	K - the 'kilo' for the 'Memory' type
=cut
use constant {
	K => 1024,
};

=begin nd
Method: is_gt ($val, $rhs)
	Is greater $val over $rhs?
	
Parameters:
	$val - LHS of <Crop:Prop::Value>
	$rhs - RHS in bytes
	
Returns:
	true - if $val is greater than $rhs
=cut
sub is_gt {
	my ($class, $val, $rhs) = @_;
	
	my $value = $val->val_int * K * K;  # Mb
	
	$value > $rhs;
}

1;
