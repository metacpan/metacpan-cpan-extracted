package Carrot;

use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*RDX_CALLER_SUB_NAME = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_SUB_NAME;
*RDX_CALLER_LINE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_LINE;

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
	*Carrot::PROGRAM_NAME = *0;
        *Carrot::EVAL_ERROR = *@;
}
return(1);
