package Carrot::Personality::Valued::File::Name::Type::Directory;
use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*OS_FS_PATH_DELIMITER = \&Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PATH_DELIMITER;

sub SPX_NAME() { 1 }
sub SPX_TYPE() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Valued::File::Name');
package main_ {
        *Carrot::Personality::Valued::File::Name::Type::Directory::OS_ERROR = *!;
        *Carrot::Personality::Valued::File::Name::Type::Directory::ARGUMENTS = *_;
}

return(1);
