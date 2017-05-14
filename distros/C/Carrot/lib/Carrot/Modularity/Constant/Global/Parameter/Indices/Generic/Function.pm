package Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Function
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Indices/Generic/Function./manual_modularity.pl');
	} #BEGIN

	sub SPX_1ST_ARGUMENT() { 0 }
	sub SPX_2ND_ARGUMENT() { 1 }
	sub SPX_3RD_ARGUMENT() { 2 }
	sub SPX_4TH_ARGUMENT() { 3 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('SPX_', [qw(
		1ST_ARGUMENT
		2ND_ARGUMENT
		3RD_ARGUMENT
		4TH_ARGUMENT)]);
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
