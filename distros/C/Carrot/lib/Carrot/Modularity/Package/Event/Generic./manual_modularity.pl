package Carrot::Modularity::Package::Event::Generic;

use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false(
	$TRACE_FLAG);

require Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method;
*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_BEFORE() { 0 }
sub ATR_AFTER() { 1 }

sub SPX_CLASS() { 0 }
sub SPX_PKG_NAME() { 1 }
sub SPX_PKG_FILE() { 2 }
sub SPX_SUBSCRIBER() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::Many_Declared');
Carrot::Meta::Greenhouse::Package_Loader::mark_singular;
package main_ {
	*Carrot::Modularity::Package::Event::Generic::ARGUMENTS = *_;
}

return(1);
