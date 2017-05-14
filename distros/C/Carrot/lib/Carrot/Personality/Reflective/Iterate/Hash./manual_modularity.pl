package Carrot::Personality::Reflective::Iterate::Hash;
use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_HASH() { 0 }
sub ATR_KEYS() { 1 }
sub ATR_KEY() { 2 }

sub SPX_HASH() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Personality::Reflective::Iterate::Hash::ARGUMENTS = *_;
}
return(1);
