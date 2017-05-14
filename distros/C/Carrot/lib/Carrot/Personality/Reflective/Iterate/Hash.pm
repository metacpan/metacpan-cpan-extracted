package Carrot::Personality::Reflective::Iterate::Hash
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Iterate/Hash./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	hash
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_HASH] = $_[SPX_HASH];
	$this->[ATR_KEYS] = IS_UNDEFINED;
	$this->[ATR_KEY] = IS_UNDEFINED;
	$this->reset;

	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_KEYS] = keys($this->[ATR_HASH]);
	$this->[ATR_KEY] = IS_UNDEFINED;
	return;
}

sub advance
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(IS_FALSE) if ($#{$this->[ATR_KEYS]} == ADX_NO_ELEMENTS);
	$this->[ATR_KEY] = shift(@{$this->[ATR_KEYS]});
	return(IS_TRUE);
}

sub current_key
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_KEY]);
}

sub current_value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_HASH]{$_[THIS][ATR_KEY]});
}

sub current_pair
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $key = $_[THIS][ATR_KEY];
	return($key, $_[THIS][ATR_HASH]{$key});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.81
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"