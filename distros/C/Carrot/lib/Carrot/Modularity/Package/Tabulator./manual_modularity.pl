package Carrot::Modularity::Package::Tabulator;
use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;
*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;

sub ATR_BORDERS() { 0 };

#*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Modularity::Package::Tabulator::ARGUMENTS = *_;
}
return(1);
