package Carrot::Modularity::Package::Expander::Level;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*SPX_CLASS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method::SPX_CLASS;
*RE_MOD_SINGLE_LINE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers::RE_MOD_SINGLE_LINE;
*RE_MOD_SAFER_UNICODE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers::RE_MOD_SAFER_UNICODE;

sub SPX_CANDIDATE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Package::_Corporate');
package main_ {
        *Carrot::Modularity::Package::Expander::Level::ARGUMENTS = *_;
}
return(1);
