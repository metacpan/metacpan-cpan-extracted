package Carrot::Modularity::Constant::Local::Subroutine_Parameters;
use strict;
use warnings;

*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous::Scalar');

package main_ {
        *Carrot::Modularity::Constant::Local::Subroutine_Parameters::ARGUMENTS = *_;
}
return(1);
