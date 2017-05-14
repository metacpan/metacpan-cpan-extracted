package Carrot::Meta::Greenhouse::Dot_Ini::Plugin_Like;
use strict;
use warnings;

*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PLUGINS() { 0 }
sub ATR_PLUGIN_NAMES() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Meta::Greenhouse::Dot_Ini::Plugin_Like::ARGUMENTS = *_;
}
return(1);
