package Carrot::Modularity::Constant::Local;
use strict;
use warnings;

*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PLUGINS() { 0 }
sub ATR_PLUGIN_NAMES() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Constant::_Corporate');

package main_ {
        *Carrot::Modularity::Constant::Local::ARGUMENTS = *_;
}
return(1);
