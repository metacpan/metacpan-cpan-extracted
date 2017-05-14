package Carrot::Meta::Greenhouse::Caller_Backtrace;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;
*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;

*RDX_INDEX_NO_MATCH = \&Carrot::Modularity::Constant::Global::Result_Indices::Index::RDX_INDEX_NO_MATCH;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_LINE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_LINE;
*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;
*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;
*RDX_CALLER_EVAL_TEXT = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_EVAL_TEXT;
*RDX_CALLER_IS_REQUIRE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_IS_REQUIRE;
*RDX_CALLER_HAS_ARGS = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_HAS_ARGS;

sub ATR_SUBJECT() { 0 }
sub SPX_RESULT() { 1 }

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Meta::Greenhouse::Caller_Backtrace::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Caller_Backtrace::MODULE_SEARCH_PATH = *main::INC{ARRAY};
        *Carrot::Meta::Greenhouse::Caller_Backtrace::ARGUMENTS = *_;
}

return(1);
