package Carrot::Meta::Provider;
use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_MANAGED_DIVERSITY() { 0 }
sub ATR_MANAGED_MODULARITY() { 1 }
sub ATR_META_MONADS() { 3 }
sub ATR_MONAD_PROVIDERS() { 4 }

sub SPX_CALLER() { 1 }
sub SPX_PKG_NAME() { 1 }
sub SPX_PKG_FILE() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Meta::Provider::EVAL_ERROR = *@;
        *Carrot::Meta::Provider::ARGUMENTS = *_;
}
return(1);
