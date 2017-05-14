package Carrot::Diversity::Attribute_Type::One_Anonymous::Hash;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

sub SPX_VALUE() { 1 }
sub SPX_KEY() { 1 }
sub SPX_NAME() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Diversity::Attribute_Type::One_Anonymous::Hash::ARGUMENTS = *_;
}
return(1);
