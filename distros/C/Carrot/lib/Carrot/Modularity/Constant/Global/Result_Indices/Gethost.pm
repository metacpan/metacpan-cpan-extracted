package Carrot::Modularity::Constant::Global::Result_Indices::Gethost
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Gethost./manual_modularity.pl');
	} #BEGIN

	sub RDX_GETHOST_NAME() { 0 }
	sub RDX_GETHOST_ALIASES() { 1 }
	sub RDX_GETHOST_ADDRESSTYPE() { 2 }
	sub RDX_GETHOST_LENGTH() { 3 }
	sub RDX_GETHOST_ADDRESSES() { 4 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GETHOST_', [qw(
		NAME
		ALIASES
		ADDRESSTYPE
		LENGTH
		ADDRESSES)]);
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
