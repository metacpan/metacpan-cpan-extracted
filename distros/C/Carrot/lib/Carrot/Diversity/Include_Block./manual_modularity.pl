package Carrot::Diversity::Include_Block;
use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

#sub ATR_PLUGINS() { 0 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Include_Block::ARGUMENTS = *_;
}
return(1);
