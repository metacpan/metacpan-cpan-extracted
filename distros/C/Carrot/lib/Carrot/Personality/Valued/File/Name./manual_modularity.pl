package Carrot::Personality::Valued::File::Name;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;
*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*THAT = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THAT;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;
*ADX_LAST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_LAST_ELEMENT;

*PKY_SPLIT_RETURN_FULL_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_RETURN_FULL_TRAIL;

*RDX_STAT_ATIME = \&Carrot::Modularity::Constant::Global::Result_Indices::Stat::RDX_STAT_ATIME;
*RDX_STAT_MTIME = \&Carrot::Modularity::Constant::Global::Result_Indices::Stat::RDX_STAT_MTIME;
*RDX_STAT_CTIME = \&Carrot::Modularity::Constant::Global::Result_Indices::Stat::RDX_STAT_CTIME;

*OS_FS_CURRENT_DIRECTORY = \&Carrot::Modularity::Constant::Global::Operating_System::OS_FS_CURRENT_DIRECTORY;
*OS_FS_PARENT_DIRECTORY = \&Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PARENT_DIRECTORY;
*OS_FS_PATH_DELIMITER = \&Carrot::Modularity::Constant::Global::Operating_System::OS_FS_PATH_DELIMITER;

*PKY_SPLIT_RETURN_FULL_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_RETURN_FULL_TRAIL;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;

sub SPX_NAME() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Elemental::Scalar::Textual::File_Name');
package main_ {
        *Carrot::Personality::Valued::File::Name::ARGUMENTS = *_;
}
return(1);
