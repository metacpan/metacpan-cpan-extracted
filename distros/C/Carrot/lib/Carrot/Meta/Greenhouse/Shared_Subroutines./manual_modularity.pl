package Carrot::Meta::Greenhouse::Shared_Subroutines;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

sub SPX_PKG_NAME() { 0 }

package main_ {
        *Carrot::Meta::Greenhouse::Shared_Subroutines::ARGUMENTS = *_;
}
return(1);
