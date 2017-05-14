package Carrot::Meta::Greenhouse::Translated_Errors::Language;
use strict;
use warnings;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
package main_ {
        *Carrot::Meta::Greenhouse::Translated_Errors::Language::ARGUMENTS = *_;
        *Carrot::Meta::Greenhouse::Translated_Errors::Language::PROCESS_ENVIRONMENT = *main::ENV{HASH};
}
return(1);
