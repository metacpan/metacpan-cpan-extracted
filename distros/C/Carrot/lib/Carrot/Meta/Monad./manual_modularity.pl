package Carrot::Meta::Monad;
use strict;
use warnings;

my $carrot_arguments = Carrot::Meta::Greenhouse::Carrot_Arguments
	->constructor;
$carrot_arguments->assign_if_exists('carrot-mode', my $carrot_mode);

*DEVELOPMENT_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false
	($carrot_mode eq 'development');

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;

*RDX_CALLER_PACKAGE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_PACKAGE;
*RDX_CALLER_FILE = \&Carrot::Modularity::Constant::Global::Result_Indices::Caller::RDX_CALLER_FILE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PACKAGE_NAME() { 0 }
sub ATR_PACKAGE_FILE() { 1 }
sub ATR_DOT_DIRECTORY() { 2 }
sub ATR_SOURCE_CODE() { 3 }
sub ATR_PARENT_CLASSES() { 4 }
sub ATR_PRINCIPLE() { 5 }

sub SPX_FILE_NAME() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Meta::Monad::ARGUMENTS = *_;
}

return(1);
