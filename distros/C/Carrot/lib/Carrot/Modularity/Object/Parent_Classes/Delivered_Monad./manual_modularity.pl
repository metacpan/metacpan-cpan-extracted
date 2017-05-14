package Carrot::Modularity::Object::Parent_Classes::Delivered_Monad;

use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*ATR_PACKAGE_NAME = \&Carrot::Modularity::Object::Parent_Classes::Monad::ATR_PACKAGE_NAME;
*ATR_PERL_ISA = \&Carrot::Modularity::Object::Parent_Classes::Monad::ATR_PERL_ISA;
*ATR_ATTRIBUTE_TYPE = \&Carrot::Modularity::Object::Parent_Classes::Monad::ATR_ATTRIBUTE_TYPE;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Modularity::Object::Parent_Classes::Monad');
package main_ {
        *Carrot::Modularity::Object::Parent_Classes::Delivered_Monad::ARGUMENTS = *_;
}
return(1);
