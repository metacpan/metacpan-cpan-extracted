package Carrot::Personality::Elemental::Array::Numbers;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;
*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_VALUE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(qw(
	::Personality::Elemental::Array::Text_or_Number
	::Diversity::Attribute_Type::One_Anonymous::Array);
package main_ {
        *Carrot::Personality::Elemental::Array::Numbers::ARGUMENTS = *_;
}
return(1);
