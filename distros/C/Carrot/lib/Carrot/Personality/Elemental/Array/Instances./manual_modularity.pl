package Carrot::Personality::Elemental::Array::Instances;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_VALUE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Elemental::Array::Objects');
package main_ {
        *Carrot::Personality::Elemental::Array::Instances::ARGUMENTS = *_;
}
return(1);
