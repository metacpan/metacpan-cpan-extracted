package Carrot::Modularity::Constant::Global::Parameter::Indices::Exit
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Indices/Exit./manual_modularity.pl');
	} #BEGIN

	sub PDX_EXIT_SUCCESS() { 0 };
	sub PDX_EXIT_FAILURE() { -1 };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PDX_EXIT_', [qw(
		SUCCESS
		FAILURE)]);
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
