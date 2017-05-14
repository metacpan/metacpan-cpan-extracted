package Carrot::Modularity::Constant::Global::Result_Indices::Getnet
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Getnet./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETNET_NAME() { 0 }
	sub RDX_GETNET_ALIASES() { 1 }
	sub RDX_GETNET_ADDRTYPE() { 2 }
	sub RDX_GETNET_NET() { 3 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETNET_', [qw(
		NAME
		ALIASES
		ADDRTYPE
		NET)]);
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
