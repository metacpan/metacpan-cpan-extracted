package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification::Line;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification::Line::ARGUMENTS = *_;
}
return(1);
