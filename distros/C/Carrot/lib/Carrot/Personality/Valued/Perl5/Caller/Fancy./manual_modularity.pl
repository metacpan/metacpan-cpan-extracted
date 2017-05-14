package Carrot::Personality::Valued::Perl5::Caller::Fancy;
use strict;
use warnings;


*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Valued::Perl5::Caller');
package main_ {
        *Carrot::Personality::Valued::Perl5::Caller::Fancy::ARGUMENTS = *_;
}
return(1);
