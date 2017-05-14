package Carrot::Modularity::Constant::Global::Operating_System;

use strict;
use warnings;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Modularity::Constant::Global::Operating_System::OS_NAME = *^O;
}

return(1);
