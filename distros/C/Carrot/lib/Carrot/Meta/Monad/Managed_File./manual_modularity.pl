package Carrot::Meta::Monad::Managed_File;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_NAME() { 0 }
sub ATR_NEEDS_UPDATE() { 1 }
sub ATR_PKG_MTIME() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
	*Carrot::Meta::Monad::Managed_File::ARGUMENTS = *_;
}

return(1);
