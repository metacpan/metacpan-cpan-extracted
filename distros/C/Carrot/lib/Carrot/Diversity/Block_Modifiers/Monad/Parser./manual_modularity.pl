package Carrot::Diversity::Block_Modifiers::Monad::Parser;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;
*ADX_LAST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_LAST_ELEMENT;
*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

sub ATR_MONAD() { 0 }
sub ATR_ALL_BLOCKS() { 1 }

sub MLX_BLOCK_OPEN_CLOSE() { 0 }
sub MLX_BLOCK_MODIFIER() { 1 }
sub MLX_BLOCK_END() { 2 }

sub MLX_BLOCK_TYPE() { 0 }
sub MLX_BLOCK_NAME() { 1 }
sub MLX_BLOCK_KEYWORD() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');
package main_ {
        *Carrot::Diversity::Block_Modifiers::Monad::Parser::ARGUMENTS = *_;
}
return(1);
