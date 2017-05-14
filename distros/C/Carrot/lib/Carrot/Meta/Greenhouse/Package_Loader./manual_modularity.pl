package Carrot::Meta::Greenhouse::Package_Loader;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

#FIXME: why require all of a sudden?
require Carrot::Modularity::Constant::Global::Result_Indices::Caller;
*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

sub SPX_PKG_NAME() { 1 }

package main_ {
	*Carrot::Meta::Greenhouse::Package_Loader::ARGUMENTS = *_;
	*Carrot::Meta::Greenhouse::Package_Loader::PROGRAM_NAME = *0;
}

return(1);
