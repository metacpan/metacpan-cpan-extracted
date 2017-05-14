package Carrot::Personality::Reflective::Iterate::Array::Reverse;
use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_ELEMENTS() { 0 }
sub ATR_POSITION() { 1 }

sub SPX_ARRAY() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Reflective::Iterate::Array::Forward');
package main_ {
        *Carrot::Personality::Reflective::Iterate::Array::Reverse::ARGUMENTS = *_;
}
return(1);
