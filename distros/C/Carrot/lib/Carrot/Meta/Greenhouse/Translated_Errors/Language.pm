package Carrot::Meta::Greenhouse::Translated_Errors::Language
# /type class
# /instances singular
# /capability "Maintain the languages of error messages"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Translated_Errors/Language./manual_modularity.pl');
	} #BEGIN

	my $fallback = 'en_US';
	my $operator = exists($PROCESS_ENVIRONMENT{'LANG'})
		? join('', ($PROCESS_ENVIRONMENT{'LANG'} =~ m{\A(\w+)}si))
		: $fallback;

# =--------------------------------------------------------------------------= #

sub dot_ini_got_association
# /type method
# /effect "Processes an association from an .ini file."
# //parameters
#	name
#	value
# //returns
{
	my ($this, $name, $value) = @ARGUMENTS;

	if ($name eq 'operator')
	{
		$operator = $value;

	} elsif ($name eq 'fallback')
	{
		$fallback = $value;
	}

	return;
}

sub operator
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return($operator);
}

sub fallback
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return($fallback);
}

sub both
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return($operator, $fallback);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.76
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
