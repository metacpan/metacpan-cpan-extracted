package Carrot::Meta::Greenhouse::File_Content;

use strict;
use warnings;

our $TRACE_FLAG //= 0;
*TRACE_FLAG = Carrot::Meta::Greenhouse::Static_Flags::true_or_false($TRACE_FLAG);

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;

*OS_NEEDS_BINMODE = \&Carrot::Modularity::Constant::Global::Operating_System::OS_NEEDS_BINMODE;

*RDX_STAT_SIZE = \&Carrot::Modularity::Constant::Global::Result_Indices::Stat::RDX_STAT_SIZE;

require Carrot::Modularity::Constant::Global::Parameter::Keys::Open;
*PKY_OPEN_MODE_READ = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_READ;
*PKY_OPEN_MODE_WRITE = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_WRITE;
*PKY_OPEN_MODE_APPEND = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Open::PKY_OPEN_MODE_APPEND;

*PKY_SPLIT_RETURN_FULL_TRAIL = \&Carrot::Modularity::Constant::Global::Parameter::Keys::Split::PKY_SPLIT_RETURN_FULL_TRAIL;
*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

sub SPX_FILE_NAME() { 1 }
sub SPX_BUFFER() { 2 }

package main_ {
        *Carrot::Meta::Greenhouse::File_Content::EVAL_ERROR = *@;
        *Carrot::Meta::Greenhouse::File_Content::OS_ERROR = *!;
        *Carrot::Meta::Greenhouse::File_Content::ARGUMENTS = *_;
}

return(1);
