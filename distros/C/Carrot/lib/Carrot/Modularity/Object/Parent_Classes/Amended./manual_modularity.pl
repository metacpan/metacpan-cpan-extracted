package Carrot::Modularity::Object::Parent_Classes::Amended;

use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_RELATIONS() { 0 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Object::Parent_Classes::Amended::ARGUMENTS = *_;
}
return(1);
