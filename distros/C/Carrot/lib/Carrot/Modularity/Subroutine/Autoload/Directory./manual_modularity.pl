package Carrot::Modularity::Subroutine::Autoload::Directory;

use strict;
use warnings;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

sub ATR_PACKAGE_NAME() { 0 }
sub ATR_CONTENT() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::Many_Declared::Ordered');

package main_ {
        *Carrot::Modularity::Subroutine::Autoload::Directory::ARGUMENTS = *_;
}
return(1);
