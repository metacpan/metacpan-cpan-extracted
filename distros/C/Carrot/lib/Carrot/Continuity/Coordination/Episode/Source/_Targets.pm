package Carrot::Continuity::Coordination::Episode::Source::_Targets
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->distinguished_exceptions->provide(
		my $hash_element_missing = 'hash_element_missing',
		my $array_index_outbound = 'array_index_outbound');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_ARRAY] = [];
	$this->[ATR_INDEX] = {};

	return;
}

sub add
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	my ($this) = @ARGUMENTS;

	push($this->[ATR_ARRAY], $_[SPX_ELEMENT]);
	my $key = Scalar::Util::refaddr($_[SPX_ELEMENT]);
	$this->[ATR_INDEX]{$key} = $#{$this->[ATR_ARRAY]};
	return;
}

#FIXME: duplicates code of Carrot::Personality::None::Array::Indexed::Single
sub remove
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	my ($this, $element) = @ARGUMENTS;

	my $key = Scalar::Util::refaddr($element);
#FIXME: these are actually assertions
	unless (exists($this->[ATR_INDEX]{$key}))
	{
#No such element '%s' in index.
		$hash_element_missing->raise_exception(
			{'key' => $key},
			ERROR_CATEGORY_SETUP);
	}
	my $offset = delete($this->[ATR_INDEX]{$key});
	unless (exists($this->[ATR_ARRAY][$offset]))
	{
#No such offset '%s' in array.
		$array_index_outbound->raise_exception(
			{'index' => $offset,
			 'size' => scalar(@{$this->[ATR_ARRAY]})},
			ERROR_CATEGORY_SETUP);
	}
	splice($this->[ATR_ARRAY], $offset, 1);
	return;
}

sub arrayref
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ARRAY]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.58
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"