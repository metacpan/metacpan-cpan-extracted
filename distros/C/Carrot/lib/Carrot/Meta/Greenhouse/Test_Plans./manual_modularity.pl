package Carrot::Meta::Greenhouse::Test_Plans;
use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;
*ADX_LAST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_LAST_ELEMENT;

sub ATR_TOTAL() { 0 };
sub ATR_SECTIONS() { 1 };
sub ATR_SECTION() { 2 };
sub ATR_SUCCESS() { 3 };
sub ATR_FAILURE() { 4 };
sub ATR_OUT_FILE() { 5 };

sub SPX_VALUE() { 1 };

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

package main_ {
        *Carrot::Meta::Greenhouse::Test_Plans::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Test_Plans::ARGUMENTS = *_;
}

return(1);
