package Carrot::Meta::Greenhouse::Application_Directories;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_KEY() { 1 };
sub SPX_VALUE() { 2 };
sub SPX_FILE_NAME() { 1 };

Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous::Hash');

package main_ {
        *Carrot::Meta::Greenhouse::Application_Directories::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Application_Directories::OS_NAME = *^O;
        *Carrot::Meta::Greenhouse::Application_Directories::PERL_VERSION = *^V;
        *Carrot::Meta::Greenhouse::Application_Directories::PROCESS_ID = *$;
        *Carrot::Meta::Greenhouse::Application_Directories::ARGUMENTS = *_;
}

return(1);
