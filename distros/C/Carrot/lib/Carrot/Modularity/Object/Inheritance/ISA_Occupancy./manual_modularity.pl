package Carrot::Modularity::Object::Inheritance::ISA_Occupancy;
use strict;
use warnings;

*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

sub ATR_MONADS() { 0 }
sub ATR_UNIVERSAL() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Object::Inheritance::ISA_Occupancy::ARGUMENTS = *_;
}
return(1);
