package Carrot::Meta::Monad::Shortcuts;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

sub SPX_METHOD_NAME() { 3 }
package main_ {
        *Carrot::Meta::Monad::Shortcuts::ARGUMENTS = *_;
}

return(1);
