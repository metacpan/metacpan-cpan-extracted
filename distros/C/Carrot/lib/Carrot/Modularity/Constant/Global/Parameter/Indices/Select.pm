package Carrot::Modularity::Constant::Global::Parameter::Indices::Select
# /type class
# /capability ""
{
	#NOTE: select() is special due to the 2-dimensional input data

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Indices/Select./manual_modularity.pl');
	} #BEGIN

	sub PDX_SELECS_READ() { 0 };
	sub PDX_SELECS_WRITE() { 1 };
	sub PDX_SELECS_EXCEPTION() { 2 };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PDX_SELECS_', [qw(
		READ
		WRITE
		EXCEPTION)]);
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
