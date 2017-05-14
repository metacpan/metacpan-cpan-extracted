package Carrot::Modularity::Constant::Global::Result_Indices::Getpw
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Getpw./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETPW_NAME() { 0 }
	sub RDX_GETPW_PASSWORD() { 1 }
	sub RDX_GETPW_UID() { 2 }
	sub RDX_GETPW_GID() { 3 }
	sub RDX_GETPW_QUOTA() { 4 }
	sub RDX_GETPW_COMMENT() { 5 }
	sub RDX_GETPW_GCOS() { 6 }
	sub RDX_GETPW_HOME_DIRECTORY() { 7 }
	sub RDX_GETPW_SHELL() { 8 }
	sub RDX_GETPW_EXPIRATION() { 9 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETPW_', [qw(
		NAME
		PASSWORD
		UID
		GID
		QUOTA
		COMMENT
		GCOS
		HOME_DIRECTORY
		SHELL
		EXPIRATION)]);
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
