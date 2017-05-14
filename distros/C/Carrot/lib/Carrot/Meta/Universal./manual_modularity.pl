package UNIVERSAL;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *UNIVERSAL::EVAL_ERROR = *@;
        *UNIVERSAL::ARGUMENTS = *_;
}

return(1);
