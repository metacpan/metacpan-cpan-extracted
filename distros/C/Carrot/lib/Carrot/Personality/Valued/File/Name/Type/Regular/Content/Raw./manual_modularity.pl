package Carrot::Personality::Valued::File::Name::Type::Regular::Content::Raw;
use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);

*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*OS_NEEDS_BINMODE = \&Carrot::Modularity::Constant::Global::Operating_System::OS_NEEDS_BINMODE;

*RDX_STAT_SIZE = \&Carrot::Modularity::Constant::Global::Result_Indices::Stat::RDX_STAT_SIZE;

*PKY_OPEN_MODE_READ = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_READ;
*PKY_OPEN_MODE_WRITE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_WRITE;
*PKY_OPEN_MODE_APPEND = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_APPEND;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*PKY_SPLIT_RETURN_FULL_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_RETURN_FULL_TRAIL;

sub SPX_LINE() { 1 }
sub SPX_BUFFER() { 1 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package(
	'::Personality::Valued::File::Name::Type::Regular');
package main_ {
        *Carrot::Personality::Valued::File::Name::Type::Regular::Content::Raw::EVAL_ERROR = *@;
        *Carrot::Personality::Valued::File::Name::Type::Regular::Content::Raw::OS_ERROR = *!;
        *Carrot::Personality::Valued::File::Name::Type::Regular::Content::Raw::ARGUMENTS = *_;
}

return(1);
