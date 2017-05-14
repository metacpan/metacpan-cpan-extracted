package Carrot::Diversity::Block_Modifiers::Plugin::Package::Tabulators;

use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*ATR_BLOCK_ID = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_BLOCK_ID;
*ATR_VALUE = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_VALUE;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Block_Modifiers::Plugin::_Prototype');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Package::Tabulators::ARGUMENTS = *_;
}
return(1);
