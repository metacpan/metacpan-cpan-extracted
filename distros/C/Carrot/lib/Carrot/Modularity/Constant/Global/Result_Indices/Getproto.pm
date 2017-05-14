package Carrot::Modularity::Constant::Global::Result_Indices::Getproto
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Getproto./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETPROTO_NAME() { 0 }
	sub RDX_GETPROTO_ALIASES() { 1 }
	sub RDX_GETPROTO_PROTOCOL() { 2 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETPROTO_', [qw(
		NAME
		ALIASES
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
