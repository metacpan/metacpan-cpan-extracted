package Carrot::Modularity::Package::Name;
use strict;
use warnings;

our $TRACE_FLAG //= 0;
require Carrot::Meta::Greenhouse::Static_Flags;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG );

*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;
*RDX_CALLER_LINE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_LINE;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_EXISTENT = \&Carrot::Modularity::Constant::Global::Boolean::IS_EXISTENT;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_THAT() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Package::_Corporate');
package main_ {
        *Carrot::Modularity::Package::Name::ARGUMENTS = *_;
        *Carrot::Modularity::Package::Name::MODULES_LOADED = *main::INC;
}
return(1);
