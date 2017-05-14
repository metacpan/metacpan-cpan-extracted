package Carrot::Meta::Greenhouse::Translated_Errors;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;
*RDX_CALLER_LINE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_LINE;
*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;
*RDX_CALLER_IS_REQUIRE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_IS_REQUIRE;

sub SPX_PKG_FILE() { 1 }

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Translated_Errors::PROCESS_ID = *$;
        *Carrot::Meta::Greenhouse::Translated_Errors::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Translated_Errors::ARGUMENTS = *_;
}

return(1);
