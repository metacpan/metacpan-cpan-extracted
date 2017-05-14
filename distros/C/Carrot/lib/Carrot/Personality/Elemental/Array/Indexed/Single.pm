package Carrot::Personality::Elemental::Array::Indexed::Single
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $hash_element_missing = 'hash_element_missing',
		my $array_index_outbound = 'array_index_outbound');

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my $this = [];
	$this->[ATR_ARRAY] = [];
	$this->[ATR_INDEX] = {};
	bless($this, $_[THIS]);
}

sub elements
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ARRAY]);
}

sub element_at
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	::Personality::Abstract::Text
{
	return($_[THIS][ATR_ARRAY][$_[SPX_POSITION]]);
}

sub ref_element_at
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	?
{
	return(\$_[THIS][ATR_ARRAY][$_[SPX_POSITION]]);
}

sub element_named
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	return($_[THIS][ATR_ARRAY][$_[THIS][ATR_INDEX]{$_[SPX_NAME]}]);
}

sub keys
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(\CORE::keys($_[THIS][ATR_INDEX]));
}

sub reset_each
# /type method
# /effect ""
# //parameters
# //returns
{
	CORE::keys($_[THIS][ATR_INDEX]);
	return;
}

sub each
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::each($_[THIS][ATR_INDEX]));
}

sub push_nonindexed
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	CORE::push($_[THIS][ATR_ARRAY], $_[SPX_ELEMENT]);
	return;
}

sub push_autoindexed
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	my ($this) = @ARGUMENTS;

	CORE::push($this->[ATR_ARRAY], $_[SPX_ELEMENT]);
	my $key = Scalar::Util::refaddr($_[SPX_ELEMENT]);
	$this->[ATR_INDEX]{$key} = $#{$this->[ATR_ARRAY]};
	return;
}

sub push_indexed
# /type method
# /effect ""
# //parameters
#	element
#	iname
# //returns
{
	my ($this) = @ARGUMENTS;

	CORE::push($this->[ATR_ARRAY], $_[SPX_ELEMENT]);
	$this->[ATR_INDEX]{$_[SPX_INAME]} = $#{$this->[ATR_ARRAY]};
	return;
}

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
		$hash_element_missing->raise_exception(
#No such element '%s' in index.
			{'key' => $key},
			ERROR_CATEGORY_SETUP);
	}
	my $offset = delete($this->[ATR_INDEX]{$key});
	unless (exists($this->[ATR_ARRAY][$offset]))
	{
		$array_index_outbound->raise_exception(
#No such offset '%s' in array.
			{'index' => $offset,
			 'size' => scalar(@{$this->[ATR_ARRAY]})},
			ERROR_CATEGORY_SETUP);
	}
	splice($this->[ATR_ARRAY], $offset, 1);
	return;
}

sub lock
# /type method
# /effect "Locks the internal structures."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	Internals::SvREADONLY(@{$this->[ATR_ARRAY]}, 1);
	Internals::hv_clear_placeholders(%{$this->[ATR_INDEX]});
	Internals::SvREADONLY(%{$this->[ATR_INDEX]}, 1);
	return;
}

sub unlock
# /type method
# /effect "Unlocks the internal structures."
# //parameters
# //returns
{
	Internals::SvREADONLY(@{$_[THIS][ATR_ARRAY]}, 0);
	Internals::SvREADONLY(%{$_[THIS][ATR_INDEX]}, 0);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.60
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
