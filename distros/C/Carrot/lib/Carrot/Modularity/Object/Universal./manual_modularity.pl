package Carrot::Modularity::Object::Universal;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Abstract::Instance');
package main_ {
        *Carrot::Modularity::Object::Universal::ARGUMENTS = *_;
}
return(1);
