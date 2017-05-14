package Carrot::Diversity::Attribute_Type::One_Anonymous::Array;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;
*ADX_LAST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_LAST_ELEMENT;
*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

sub SPX_VALUE() { 1 }
sub SPX_VALUES() { 1 }
sub SPX_POSITION() { 1 }
sub SPX_ELEMENT() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Diversity::Attribute_Type::One_Anonymous::Array::ARGUMENTS = *_;
}
return(1);
