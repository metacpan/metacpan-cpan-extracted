package Carrot::Modularity::Object::Parent_Classes::Monad;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PACKAGE_NAME() { 0 }
sub ATR_PERL_ISA() { 1 }
sub ATR_ATTRIBUTE_TYPE() { 2 }

sub SPX_VALUE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Object::Parent_Classes::Monad::ARGUMENTS = *_;
}
return(1);
