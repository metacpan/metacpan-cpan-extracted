package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Type_Implementation;

use strict;
use warnings;

*ATR_BLOCK_ID = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_BLOCK_ID;
*ATR_VALUE = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_VALUE;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Block_Modifiers::Plugin::_Prototype');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Type_Implementation::ARGUMENTS = *_;
}
return(1);
