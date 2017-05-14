package Carrot::Modularity::Object::Parent_Classes;
use strict;
use warnings;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

sub ATR_MONADS() { 0 }
sub ATR_MONAD_CLASS() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Constant::Parental::_Corporate');
package main_ {
        *Carrot::Modularity::Object::Parent_Classes::ARGUMENTS = *_;
}
return(1);
