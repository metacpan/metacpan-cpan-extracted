package Carrot::Modularity::Constant::Global::Parameter::Indices::Caller
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Indices/Caller./manual_modularity.pl');
	} #BEGIN

	sub PKY_CALLER_0_FRAMES() { 0 };
	sub PKY_CALLER_1_FRAME() { 1 };
	sub PKY_CALLER_2_FRAMES() { 2 };
	sub PKY_CALLER_3_FRAMES() { 3 };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PKY_CALLER_', [qw(
		0_FRAMES
		1_FRAME
		2_FRAMES
		3_FRAMES)]);
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
