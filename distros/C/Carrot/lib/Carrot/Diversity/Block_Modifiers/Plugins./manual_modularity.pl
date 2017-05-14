package Carrot::Diversity::Block_Modifiers::Plugins;
use strict;
use warnings;

sub ATR_PLUGINS() { 0 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugins::ARGUMENTS = *_;
}
return(1);
