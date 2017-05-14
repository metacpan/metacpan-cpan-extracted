package Carrot::Modularity::Constant::Parental::Ordered_Attributes::Monad;

use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

#*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_META_MONAD() { 0 }
sub ATR_NAMES() { 1 }
sub ATR_LOWEST_INDEX() { 2 }
sub ATR_HIGHEST_INDEX() { 3 }

sub SPX_BOUNDARY() { 3 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Constant::Parental::Ordered_Attributes::Monad::ARGUMENTS = *_;
}
return(1);
