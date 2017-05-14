package Carrot::Personality::Elemental::Array::Text_or_Number;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub SPX_VALUE() { 1 }

package main_ {
        *Carrot::Personality::Elemental::Array::Text_or_Number::ARGUMENTS = *_;
}
return(1);
