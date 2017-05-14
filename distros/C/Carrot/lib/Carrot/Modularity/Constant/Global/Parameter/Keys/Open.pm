package Carrot::Modularity::Constant::Global::Parameter::Keys::Open
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Keys/Open./manual_modularity.pl');
	} #BEGIN

	sub PKY_OPEN_MODE_READ() { '<' };
	sub PKY_OPEN_MODE_READ_WRITE() { '+<' };
	sub PKY_OPEN_MODE_WRITE() { '>' };
	sub PKY_OPEN_MODE_WRITE_READ() { '+>' };
	sub PKY_OPEN_MODE_APPEND() { '>>' };
	sub PKY_OPEN_MODE_APPEND_READ() { '+>>' };
	sub PKY_OPEN_MODE_DUPLICATE() { '&' };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PKY_OPEN_MODE_', [qw(
		READ
		READ_WRITE
		WRITE
		WRITE_READ
		APPEND
		APPEND_READ
		DUPLICATE_WRITE
		DUPLICATE_WRITE_READ)]);
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
