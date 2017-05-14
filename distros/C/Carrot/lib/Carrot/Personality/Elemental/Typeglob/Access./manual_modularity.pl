package Carrot::Personality::Elemental::Typeglob::Access;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

sub SPX_VALUE() { 1 }

package main_ {
        *Carrot::Personality::Elemental::Typeglob::Access::ARGUMENTS = *_;
}
return(1);
