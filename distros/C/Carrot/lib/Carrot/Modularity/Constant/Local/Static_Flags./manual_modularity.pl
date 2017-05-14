package Carrot::Modularity::Constant::Local::Static_Flags;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PACKAGE_RULES() { 0 }
sub ATR_PREFIX_RULES() { 1 }

Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Constant::Local::Static_Flags::ARGUMENTS = *_;
}
return(1);
