package Carrot::Personality::Valued::Perl5::Eval_Error;
use strict;
use warnings;

*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;

*ADX_FIRST_ELEMENT = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_FIRST_ELEMENT;

*EVAL_ERROR_COOKED = \&Carrot::Modularity::Constant::Global::Error_Categories::Eval::EVAL_ERROR_COOKED;
*EVAL_ERROR_NONE = \&Carrot::Modularity::Constant::Global::Error_Categories::Eval::EVAL_ERROR_NONE;
*EVAL_ERROR_RAW = \&Carrot::Modularity::Constant::Global::Error_Categories::Eval::EVAL_ERROR_RAW;

*ERROR_CATEGORY_META = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_META;
*ERROR_CATEGORY_SETUP = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_SETUP;
*ERROR_CATEGORY_IMPLEMENTATION = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_IMPLEMENTATION;
*ERROR_CATEGORY_USAGE = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_USAGE;
*ERROR_CATEGORY_POLICY = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_POLICY;
*ERROR_CATEGORY_RESOURCES = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_RESOURCES;
*ERROR_CATEGORY_OS_PROCESS = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_OS_PROCESS;
*ERROR_CATEGORY_OS_SIGNAL_ALARM = \&Carrot::Modularity::Constant::Global::Error_Categories::Application::ERROR_CATEGORY_OS_SIGNAL_ALARM;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

sub ATR_STATUS() { 0 }
sub ATR_CATCHER() { 1 }
sub ATR_ERROR() { 2 }

sub SPX_ERROR() { 1 }

package main_ {
        *Carrot::Personality::Valued::Perl5::Eval_Error::ARGUMENTS = *_;
}

return(1);
