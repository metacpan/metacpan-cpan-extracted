package Carrot::Modularity::Constant::Global::Error_Categories::Eval
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Error_Categories/Eval./manual_modularity.pl');
	} #BEGIN

	sub EVAL_ERROR_COOKED() { -1 }
	sub EVAL_ERROR_NONE()   { 0 }
	sub EVAL_ERROR_RAW()    { 1 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('EVAL_ERROR', [qw(
		COOKED
		NONE
		RAW)]);
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
