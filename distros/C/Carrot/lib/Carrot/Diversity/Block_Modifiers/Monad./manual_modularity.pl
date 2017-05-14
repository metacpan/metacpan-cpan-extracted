package Carrot::Diversity::Block_Modifiers::Monad;
use strict;
use warnings;

our $DEBUG_FLAG //= 0;
*DEBUG_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($DEBUG_FLAG);

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

sub ATR_ALL_BLOCKS() { 0 }
sub ATR_TRIGGER() { 1 }
sub ATR_PARSER() { 2 }

sub SPX_TRIGGER() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Monad::EVAL_ERROR = *@;
        *Carrot::Diversity::Block_Modifiers::Monad::ARGUMENTS = *_;
}
return(1);
