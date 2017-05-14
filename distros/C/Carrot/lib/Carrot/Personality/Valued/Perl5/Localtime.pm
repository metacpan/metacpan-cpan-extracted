package Carrot::Personality::Valued::Perl5::Localtime
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Perl5/Localtime./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub second
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_SECOND]);
}

sub minute
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_MINUTE]);
}

sub hour
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_HOUR]);
}

sub day_of_month
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_DAY_OF_MONTH]);
}

sub month
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_MONTH]);
}

sub year
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_YEAR]);
}

sub week_day
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_WEEK_DAY]);
}

sub year_day
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_LOCALTIME_YEAR_DAY]);
}

sub is_dst
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][RDX_LOCALTIME_IS_DST]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.47
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
