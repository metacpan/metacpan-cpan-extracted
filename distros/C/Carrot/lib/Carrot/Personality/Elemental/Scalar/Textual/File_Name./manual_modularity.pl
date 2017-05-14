package Carrot::Personality::Elemental::Scalar::Textual::File_Name;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

*OS_FS_PATH_DELIMITER = \&Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PATH_DELIMITER;

sub SPX_VALUE() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Elemental::Scalar::Textual');
package main_ {
        *Carrot::Personality::Elemental::Scalar::Textual::File_Name::ARGUMENTS = *_;
}
return(1);
