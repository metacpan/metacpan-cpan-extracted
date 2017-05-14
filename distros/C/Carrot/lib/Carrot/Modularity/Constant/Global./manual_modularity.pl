package Carrot::Modularity::Constant::Global;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

#Irritating order, but correct; a polymorphism so to say
sub ATR_PLUGIN_NAMES() { 0 };
sub ATR_PATTERNS() { 1 };

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Constant::_Corporate');

package main_ {
        *Carrot::Modularity::Constant::Global::ARGUMENTS = *_;
}
return(1);
