package Carrot::Diversity::Attribute_Type::One_Anonymous::Typeglob;
use strict;
use warnings;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Diversity::Attribute_Type::One_Anonymous::Typeglob::ARGUMENTS = *_;
}
return(1);
