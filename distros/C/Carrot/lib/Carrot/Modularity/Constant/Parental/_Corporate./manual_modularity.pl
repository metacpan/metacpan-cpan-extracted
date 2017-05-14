package Carrot::Modularity::Constant::Parental::_Corporate;

use strict;
use warnings;

our $OPTIMIZE_FLAG //= 1;
*OPTIMIZE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false(
	$OPTIMIZE_FLAG);

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_MONADS() { 0 }
sub ATR_MONAD_CLASS() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Constant::Parental::_Corporate::ARGUMENTS = *_;
}
return(1);
