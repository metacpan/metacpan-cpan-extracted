package Carrot::Modularity::Package::Loader;

use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);
our $MAP_FLAG //= 0;
*MAP_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($MAP_FLAG);

#our $SHADOW_FLAG //= 0;
#*SHADOW_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($SHADOW_FLAG);

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
#*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
#*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

sub SPX_PKG_FILE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Modularity::Package::Loader::EVAL_ERROR = *@;
#        *Carrot::Modularity::Package::Loader::EXCEPTIONS_BEING_CAUGHT = *^S;
        *Carrot::Modularity::Package::Loader::ARGUMENTS = *_;
        *Carrot::Modularity::Package::Loader::MODULES_LOADED = *main::INC{HASH};
}

return(1);
