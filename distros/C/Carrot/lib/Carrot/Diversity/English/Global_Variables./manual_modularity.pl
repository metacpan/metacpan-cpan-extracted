package Carrot::Diversity::English::Global_Variables;

use strict;
use warnings;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Diversity::English::Global_Variables::ARGUMENTS = *_;
}
return(1);
