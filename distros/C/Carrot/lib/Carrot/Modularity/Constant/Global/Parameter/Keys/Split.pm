package Carrot::Modularity::Constant::Global::Parameter::Keys::Split
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Keys/Split./manual_modularity.pl');
	} #BEGIN

	sub PKY_SPLIT_RETURN_FULL_TRAIL() { -1 }
	sub PKY_SPLIT_IGNORE_EMPTY_TRAIL() { 0 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PKY_SPLIT_', [qw(
		RETURN_FULL_TRAIL
		IGNORE_EMPTY_TRAIL)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.17
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
