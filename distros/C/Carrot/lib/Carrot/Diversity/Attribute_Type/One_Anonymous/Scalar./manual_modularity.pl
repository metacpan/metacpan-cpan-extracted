package Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

sub SPX_CLASS() { 0 }
sub SPX_VALUE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar::ARGUMENTS = *_;
}
return(1);
