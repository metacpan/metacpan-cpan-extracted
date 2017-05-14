package Carrot::Modularity::Package::File_Name::Combination;

use strict;
use warnings;

*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
package main_ {
	*Carrot::Modularity::Package::File_Name::Combination::MODULE_SEARCH_PATH = *main::INC{ARRAY};
        *Carrot::Modularity::Package::File_Name::Combination::ARGUMENTS = *_;
}

return(1);
