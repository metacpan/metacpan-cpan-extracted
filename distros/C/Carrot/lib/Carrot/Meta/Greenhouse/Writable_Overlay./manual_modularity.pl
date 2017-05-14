package Carrot::Meta::Greenhouse::Writable_Overlay;
use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);

our $REDIRECT_FLAG //= (not -w __FILE__);
*REDIRECT_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($REDIRECT_FLAG);

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*PKY_OPEN_MODE_READ_WRITE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_READ_WRITE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Meta::Greenhouse::Writable_Overlay::MODULE_SEARCH_PATH = *main::INC{ARRAY};
        *Carrot::Meta::Greenhouse::Writable_Overlay::ARGUMENTS = *_;
}

return(1);
