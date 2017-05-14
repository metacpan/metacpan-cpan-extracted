package Carrot::Modularity::Constant::_Corporate;
use strict;
use warnings;

require Carrot::Modularity::Constant::Global::Boolean;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;

sub ATR_PLUGINS() { 0 }
sub ATR_PLUGIN_NAMES() { 1 }
sub ATR_PATTERNS() { 1 } #ugly

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Meta::Greenhouse::Dot_Ini::Plugin_Like');

package main_ {
        *Carrot::Modularity::Constant::_Corporate::ARGUMENTS = *_;
}
return(1);
