package Carrot::Meta::Greenhouse::Site_Directories;
use strict;
use warnings;

sub SPX_PKG_FILE() { 1 }
sub SPX_SUBDIRECTORY() { 1 }
sub SPX_FILE_NAME() { 1 }

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Site_Directories::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Site_Directories::ARGUMENTS = *_;
}

return(1);
