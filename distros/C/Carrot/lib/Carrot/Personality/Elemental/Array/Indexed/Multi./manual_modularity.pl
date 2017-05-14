package Carrot::Personality::Elemental::Array::Indexed::Multi;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_ARRAY() { 0 }
sub ATR_INDEX() { 1 }

sub SPX_POSITION() { 1 }
sub SPX_NAME() { 1 }
sub SPX_ELEMENT() { 1 }
sub SPX_INAME() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Elemental::Array::Indexed::Single');
package main_ {
        *Carrot::Personality::Elemental::Array::Indexed::Multi::ARGUMENTS = *_;
}
return(1);
