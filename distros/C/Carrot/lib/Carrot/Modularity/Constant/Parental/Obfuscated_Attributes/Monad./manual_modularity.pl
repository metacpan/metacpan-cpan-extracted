package Carrot::Modularity::Constant::Parental::Obfuscated_Attributes::Monad;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

sub ATR_NAMES() { 0 }
sub ATR_META_MONAD() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Constant::Parental::Obfuscated_Attributes::Monad::ARGUMENTS = *_;
}
return(1);
