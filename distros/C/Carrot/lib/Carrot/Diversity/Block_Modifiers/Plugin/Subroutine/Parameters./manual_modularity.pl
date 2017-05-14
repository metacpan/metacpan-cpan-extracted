package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters;

use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;
*RDX_INDEX_NO_MATCH = \&Carrot::Modularity::Constant::Global::Result_Indices::Index::RDX_INDEX_NO_MATCH;

*ATR_BLOCK_ID = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_BLOCK_ID;
*ATR_VALUE = \&Carrot::Diversity::Block_Modifiers::Plugin::_Prototype::ATR_VALUE;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Block_Modifiers::Plugin::_Prototype');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::ARGUMENTS = *_;
}
return(1);
