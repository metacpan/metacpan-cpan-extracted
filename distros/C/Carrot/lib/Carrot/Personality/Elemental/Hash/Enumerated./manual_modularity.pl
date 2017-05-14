package Carrot::Personality::Elemental::Hash::Enumerated;
use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_INDEX() { 0 }
sub ATR_ARRAY() { 1 }

sub SPX_POSITION() { 1 }
sub SPX_NAME() { 1 }
sub SPX_ELEMENT() { 2 }

package main_ {
        *Carrot::Personality::Elemental::Hash::Enumerated::ARGUMENTS = *_;
}
return(1);
