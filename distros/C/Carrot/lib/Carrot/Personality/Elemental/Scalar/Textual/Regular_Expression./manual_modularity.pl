package Carrot::Personality::Elemental::Scalar::Textual::Regular_Expression;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

sub SPX_VALUE() { 1 }
sub SPX_REPLACEMENT() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Elemental::Scalar::Textual');
package main_ {
        *Carrot::Personality::Elemental::Scalar::Textual::Regular_Expression::ARGUMENTS = *_;
}
return(1);
