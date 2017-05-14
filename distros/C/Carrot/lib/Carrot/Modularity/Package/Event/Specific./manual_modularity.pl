package Carrot::Modularity::Package::Event::Specific;

use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false(
	$TRACE_FLAG );

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

sub ATR_CALLBACKS() { 0 }
sub ATR_COUNTER() { 1 }
sub ATR_IDS() { 2 }
sub ATR_UPGRADES() { 3 }

sub SPX_CLASS() { 0 }
sub SPX_PKG_NAME() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::Many_Declared');
package main_ {
        *Carrot::Modularity::Package::Event::Specific::ARGUMENTS = *_;
}
return(1);
