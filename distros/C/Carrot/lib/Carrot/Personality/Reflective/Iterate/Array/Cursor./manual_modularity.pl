package Carrot::Personality::Reflective::Iterate::Array::Cursor;
use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_ELEMENTS() { 0 }
sub ATR_POSITION() { 1 }
sub ATR_CURSOR() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Reflective::Iterate::Array::Forward');
package main_ {
        *Carrot::Personality::Reflective::Iterate::Array::Cursor::ARGUMENTS = *_;
}
return(1);
