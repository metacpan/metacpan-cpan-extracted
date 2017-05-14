package Carrot::Meta::Greenhouse::Dot_Ini::Startup;
use strict;
use warnings;

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*PKY_SPLIT_RETURN_FULL_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_RETURN_FULL_TRAIL;
*PKY_SPLIT_IGNORE_EMPTY_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_IGNORE_EMPTY_TRAIL;

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Diversity::Attribute_Type::One_Anonymous::Scalar');

package main_ {
        *Carrot::Meta::Greenhouse::Dot_Ini::Startup::PROGRAM_NAME = *0;
        *Carrot::Meta::Greenhouse::Dot_Ini::Startup::ARGUMENTS = *_;
        *Carrot::Meta::Greenhouse::Dot_Ini::Startup::PROGRAM_ARGUMENTS = *main::ARGV{ARRAY};
        *Carrot::Meta::Greenhouse::Dot_Ini::Startup::PROCESS_ENVIRONMENT = *main::ENV{HASH};
}

return(1);
