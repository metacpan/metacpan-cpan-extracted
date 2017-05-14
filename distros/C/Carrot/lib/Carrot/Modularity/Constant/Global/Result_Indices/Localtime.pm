package Carrot::Modularity::Constant::Global::Result_Indices::Localtime
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Localtime./manual_modularity.pl');
	} #BEGIN

	sub RDX_LOCALTIME_SECOND() { 0 };
	sub RDX_LOCALTIME_MINUTE() { 1 };
	sub RDX_LOCALTIME_HOUR() { 2 };
	sub RDX_LOCALTIME_DAY_OF_MONTH() { 3 };
	sub RDX_LOCALTIME_MONTH() { 4 };
	sub RDX_LOCALTIME_YEAR() { 5 };
	sub RDX_LOCALTIME_WEEK_DAY() { 6 };
	sub RDX_LOCALTIME_YEAR_DAY() { 7 };
	sub RDX_LOCALTIME_IS_DST() { 8 };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_LOCALTIME_', [qw(
		SECOND
		MINUTE
		HOUR
		DAY_OF_MONTH
		MONTH
		YEAR
		WEEK_DAY
		YEAR_DAY
		IS_DST)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.38
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
