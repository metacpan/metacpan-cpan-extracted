package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification;

use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;
*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;

sub ATR_MINIMUM() { 0 }
sub ATR_MAXIMUM() { 1 }
sub ATR_MULTIPLE() { 2 }
sub ATR_WILD() { 3 }
sub ATR_TYPES() { 4 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification::ARGUMENTS = *_;
}
return(1);
