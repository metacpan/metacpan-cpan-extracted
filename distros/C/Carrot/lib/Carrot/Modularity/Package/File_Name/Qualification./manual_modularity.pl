package Carrot::Modularity::Package::File_Name::Qualification;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

sub SPX_PKG_FILE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
package main_ {
	*Carrot::Modularity::Package::File_Name::Qualification::MODULE_SEARCH_PATH = *main::INC{ARRAY};
        *Carrot::Modularity::Package::File_Name::Qualification::ARGUMENTS = *_;
}
return(1);
