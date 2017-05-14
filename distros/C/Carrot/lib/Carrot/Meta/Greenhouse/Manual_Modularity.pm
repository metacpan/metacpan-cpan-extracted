package Carrot::Meta::Greenhouse::Manual_Modularity
# /type library
# /capability "Require manual_modularity.pl relatively to the package"
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub SPX_PKG_NAME() { 0 };
sub require($)
# /type function
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
# //returns
#	?
{
	CORE::require (($_[SPX_PKG_NAME] =~ s{::}{/}sgaar).'./manual_modularity.pl');
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.30
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
