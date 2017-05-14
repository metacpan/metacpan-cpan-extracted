package Carrot::Productivity::Text::Placeholder::Miniplate::Hash
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_HASH] = {};

	return;
}

sub set_element
# /type method
# /effect ""
# //parameters
#	key
#	value
# //returns
{
	my ($this, $key, $value) = @ARGUMENTS;

	$this->[ATR_HASH]{$key} = $value;
	return;
}

my $can = IS_UNDEFINED;
sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	my ($this, $placeholder) = @ARGUMENTS;

	return(IS_UNDEFINED) unless (exists($this->[ATR_HASH]{$placeholder}));

	return([$can, [$this, $placeholder]]);
}

sub syp_hash_key_find_call
# /type method
# /effect ""
# //parameters
#	key
# //returns
#	?
{
	my ($this, $key) = @ARGUMENTS;

	return($this->[ATR_HASH]{$key});
#	return($_[THIS][ATR_HASH]{$_[SPX_KEY]});
}
$can = \&syp_hash_key_find_call;

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.48
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"