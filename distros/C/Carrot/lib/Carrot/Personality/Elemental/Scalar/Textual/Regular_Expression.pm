package Carrot::Personality::Elemental::Scalar::Textual::Regular_Expression
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Scalar/Textual/Regular_Expression./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub matches
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return($_[SPX_VALUE] =~ m{${$_[THIS]}});
}

sub matches_in_array
# /type method
# /effect ""
# //parameters
#	array
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $array) = @ARGUMENTS;

	for (@$array) {
		return(IS_TRUE) if ($_ =~ m{$$this});
	}
	return(IS_FALSE);
}

sub substitute
# /type method
# /effect ""
# //parameters
#	value
#	replacement
# //returns
#	?
{
	return($_[SPX_VALUE] =~ s{${$_[THIS]}}{$_[SPX_REPLACEMENT]});
}

sub substituted
# /type method
# /effect ""
# //parameters
#	value
#	replacement
# //returns
#	?
{
	return($_[SPX_VALUE] =~ s{${$_[THIS]}}{$_[SPX_REPLACEMENT]}r); #note r
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.97
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
