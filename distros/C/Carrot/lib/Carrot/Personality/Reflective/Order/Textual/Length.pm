package Carrot::Personality::Reflective::Order::Textual::Length
# /type class
# /capability ""
{
	die('#FIXME: appears to be unused');

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Order/Textual/Length./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	elements
# //returns
{
	my ($this, $elements) = @ARGUMENTS;

	@$this = map([$_, length($_)], @$elements);

	return;
}

sub sort
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(sort(compare @{$_[THIS]}));
}

sub compare($$)
# /type function
# /effect ""
# //parameters
#	a
#	b
# //returns
#	?
{
	return($_[SPX_1ST_ARGUMENT][1] <=> $_[SPX_2ND_ARGUMENT][1]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.43
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"