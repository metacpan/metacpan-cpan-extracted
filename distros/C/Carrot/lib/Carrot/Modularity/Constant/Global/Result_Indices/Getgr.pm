package Carrot::Modularity::Constant::Global::Result_Indices::Getgr
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Getgr./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETGR_NAME() { 0 }
	sub RDX_GETGR_PASSWORD() { 1 }
	sub RDX_GETGR_GID() { 2 }
	sub RDX_GETGR_MEMBERS() { 3 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETGR_', [qw(
		NAME
		PASSWORD
		GID
		MEMBERS)]);
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
