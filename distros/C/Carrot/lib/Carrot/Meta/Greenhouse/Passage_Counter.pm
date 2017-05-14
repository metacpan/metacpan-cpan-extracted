package Carrot::Meta::Greenhouse::Passage_Counter
# /type class
# /attribute_type ::One_Anonymous::Hash
# /capability "Allows to avoid infinite loops and duplicates"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Passage_Counter./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub is_second_pass
# /type method
# /effect "Keeps track of calls to itself"
# //parameters
#	key
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $key) = @ARGUMENTS;

	return(IS_TRUE) if (exists($this->{$key}));
	$this->{$key} = IS_EXISTENT;
	return(IS_FALSE);
}

sub was_seen_before
# /type method
# /effect "Keeps track of calls to itself"
# //parameters
#	key
# //returns
#	::Personality::Abstract::Boolean
{
	return(exists($_[THIS]->{$_[SPX_KEY]}) ? IS_TRUE : IS_FALSE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.39
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
