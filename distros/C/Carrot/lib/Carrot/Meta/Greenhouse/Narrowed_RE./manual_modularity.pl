package Carrot::Meta::Greenhouse::Narrowed_RE;
use strict;
use warnings;

#require Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers;
#*RE_MOD_SAFER_UNICODE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers::RE_MOD_SAFER_UNICODE;
#*RE_MOD_SINGLE_LINE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers::RE_MOD_SINGLE_LINE;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
package main_ {
        *Carrot::Meta::Greenhouse::Narrowed_RE::ARGUMENTS = *_;

}

return(1);
