package Carrot::Meta::Greenhouse::Dot_Ini;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;

*RDX_INDEX_NO_MATCH = \&Carrot::Modularity::Constant::Global::Result_Indices::Index::RDX_INDEX_NO_MATCH;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;

sub ATR_SUBJECT() { 0 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
	*Carrot::Meta::Greenhouse::Dot_Ini::EVAL_ERROR = *@;
        *Carrot::Meta::Greenhouse::Dot_Ini::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Dot_Ini::ARGUMENTS = *_;
}

return(1);
