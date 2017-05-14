package Carrot::Modularity::Constant::Global::Result_Indices::Getserv
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Getserv./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETSERV_NAME() { 0 }
	sub RDX_GETSERV_ALIASES() { 1 }
	sub RDX_GETSERV_PORT() { 2 }
	sub RDX_GETSERV_PROTOCOL() { 3 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETSERV_', [qw(
		NAME
		ALIASES
		PORT
		PROTOCOL)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
