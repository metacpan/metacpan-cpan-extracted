package Carrot::Modularity::Package::Patterns;
use strict;
use warnings;

*constructor = \&Carrot::Meta::Greenhouse::Minimal_Constructor::scalar_based;

*THIS = \&Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class::THIS;

#*IS_UNDEFINED = \&Carrot::Modularity::Constant::Global::Boolean::IS_UNDEFINED;
*IS_TRUE = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
*IS_FALSE = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

*ADX_NO_ELEMENTS = \&Carrot::Modularity::Constant::Global::Array_Indices::ADX_NO_ELEMENTS;

*PERL_FILE_LOADED = \&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;

require Carrot::Modularity::Constant::Global::Text::Perl_Syntax ;
*PERL_PACKAGE_DELIMITER = \&Carrot::Modularity::Constant::Global::Text::Perl_Syntax::PERL_PACKAGE_DELIMITER;

sub SPX_PKG_NAME() { 1 }
sub SPX_PKG_FILE() { 1 }
sub SPX_PKG_ANCHOR() { 2 }

Carrot::Meta::Greenhouse::Shared_Subroutines::add_package_soon(
	'::Diversity::Attribute_Type::One_Anonymous');
package main_ {
        *Carrot::Modularity::Package::Patterns::OS_NAME = *^O;
        *Carrot::Modularity::Package::Patterns::PERL_VERSION = *^V;
        *Carrot::Modularity::Package::Patterns::ARGUMENTS = *_;
}

return(1);
