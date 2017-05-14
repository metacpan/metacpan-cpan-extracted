package Carrot::Meta::Greenhouse::Fatal_Syscalls;
use strict;
use warnings;

*SPX_1ST_ARGUMENT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method::SPX_1ST_ARGUMENT;
*SPX_2ND_ARGUMENT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method::SPX_2ND_ARGUMENT;
*SPX_3RD_ARGUMENT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method::SPX_3RD_ARGUMENT;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Fatal_Syscalls::OS_ERROR = *!;
        *Carrot::Meta::Greenhouse::Fatal_Syscalls::ARGUMENTS = *_;
}

return(1);
