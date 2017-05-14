package Carrot::Meta::Greenhouse::Compilation_Name;
use strict;
use warnings;

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Compilation_Name::PROGRAM_ARGUMENTS = *main::ARGV{ARRAY};
        *Carrot::Meta::Greenhouse::Compilation_Name::PROCESS_ENVIRONMENT = *main::ENV{HASH};
}
return(1);
