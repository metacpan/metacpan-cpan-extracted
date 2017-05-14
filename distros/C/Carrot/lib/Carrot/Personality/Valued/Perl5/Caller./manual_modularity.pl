package Carrot::Personality::Valued::Perl5::Caller;
use strict;
use warnings;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;
*RDX_CALLER_LINE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_LINE;
*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;
*RDX_CALLER_HAS_ARGS = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_HAS_ARGS;
*RDX_CALLER_WANTS_ARRAY = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_WANTS_ARRAY;
*RDX_CALLER_EVAL_TEXT = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_EVAL_TEXT;
*RDX_CALLER_IS_REQUIRE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_IS_REQUIRE;
*RDX_CALLER_HINTS = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_HINTS;
*RDX_CALLER_BIT_MASK = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_BIT_MASK;
*RDX_CALLER_HINT_HASH = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_HINT_HASH;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(qw(
	::Diversity::Attribute_Type::One_Anonymous::Existing_Reference
	::Diversity::Attribute_Type::Many_Declared::Ordered));
package main_ {
        *Carrot::Personality::Valued::Perl5::Caller::ARGUMENTS = *_;
}
return(1);
