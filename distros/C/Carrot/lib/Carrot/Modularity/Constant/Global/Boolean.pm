package Carrot::Modularity::Constant::Global::Boolean
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Boolean./manual_modularity.pl');
	} #BEGIN

	sub IS_FALSE() { 0 }
	sub IS_TRUE() { 1 }
	sub IS_UNDEFINED() { undef }
	sub IS_EXISTENT() { 1 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('IS_', [qw(
		FALSE
		TRUE
		UNDEFINED
		EXISTENT)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.54
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
