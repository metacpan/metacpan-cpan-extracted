package Carrot::Modularity::Constant::Global::Result_Indices::Gmtime
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Gmtime./manual_modularity.pl');
	} #BEGIN

	sub RDX_GMTIME_SECOND() { 0 }
	sub RDX_GMTIME_MINUTE() { 1 }
	sub RDX_GMTIME_HOUR() { 2 }
	sub RDX_GMTIME_DAY() { 3 }
	sub RDX_GMTIME_MONTH() { 4 }
	sub RDX_GMTIME_YEAR() { 5 }
	sub RDX_GMTIME_WEEKDAY() { 6 }
	sub RDX_GMTIME_YEARDAY() { 7 }
	sub RDX_GMTIME_IS_DST() { 8 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_GMTIME_', [qw(
		SECOND
		MINUTE
		HOUR
		DAY
		MONTH
		YEAR
		WEEKDAY
		YEARDAY
		IS_DST)]);
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
