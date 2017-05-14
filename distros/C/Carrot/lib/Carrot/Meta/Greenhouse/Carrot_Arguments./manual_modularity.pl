package Carrot::Meta::Greenhouse::Carrot_Arguments;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_KEY() { 1 };
sub SPX_VALUE() { 2 };

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Carrot_Arguments::PROGRAM_ARGUMENTS = *main::ARGV{ARRAY};;
        *Carrot::Meta::Greenhouse::Carrot_Arguments::ARGUMENTS = *_;
}

return(1);
