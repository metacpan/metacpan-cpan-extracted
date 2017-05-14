package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Prototype;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*ATR_BLOCK_ID = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_BLOCK_ID;
*ATR_VALUE = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_VALUE;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Block_Modifiers::Plugin::_Prototype');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Prototype::ARGUMENTS = *_;
}
return(1);
