package Carrot::Modularity::Constant::Global::Array_Indices
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Array_Indices./manual_modularity.pl');
	} #BEGIN

	sub ADX_NO_ELEMENTS() { -1 }
	sub ADX_FIRST_ELEMENT() { 0 }
	sub ADX_SECOND_ELEMENT() { 1 }
	sub ADX_LAST_ELEMENT() { -1 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('ADX_', [qw(
		NO_ELEMENTS
		FIRST_ELEMENT
		SECOND_ELEMENT
		LAST_ELEMENT)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.41
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
