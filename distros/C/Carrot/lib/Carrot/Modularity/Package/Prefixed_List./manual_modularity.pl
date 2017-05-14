package Carrot::Modularity::Package::Prefixed_List;
use strict;
use warnings;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;
*ADX_LAST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_LAST_ELEMENT;

#*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

sub SPX_PKG_NAME() { 1 }
sub SPX_ANCHOR() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous::Scalar');

package main_ {
        *Carrot::Modularity::Package::Prefixed_List::ARGUMENTS = *_;
}
return(1);
