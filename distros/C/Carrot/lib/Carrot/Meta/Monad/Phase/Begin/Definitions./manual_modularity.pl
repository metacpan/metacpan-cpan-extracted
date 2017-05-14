package Carrot::Meta::Monad::Phase::Begin::Definitions;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PKG_NAME() { 0 }
sub ATR_SOURCE_CODE() { 1 }
sub ATR_SEEN() { 2 }
sub ATR_LINES() { 3 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Meta::Monad::Phase::Begin::Definitions::ARGUMENTS = *_;
}
return(1);
