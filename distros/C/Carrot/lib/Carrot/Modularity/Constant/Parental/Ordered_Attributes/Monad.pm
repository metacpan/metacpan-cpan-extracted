package Carrot::Modularity::Constant::Parental::Ordered_Attributes::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	monad_provider  ::Modularity::Constant::Parental::Ordered_Attributes
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability ""
{
	my ($monad_provider, $inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Parental/Ordered_Attributes/Monad./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_META_MONAD] = $meta_monad;
	$this->[ATR_NAMES] = [];
	$this->[ATR_LOWEST_INDEX] = ADX_NO_ELEMENTS;
	$this->[ATR_HIGHEST_INDEX] = ADX_NO_ELEMENTS;

	return;
}

my $inherit = \&inherit;
sub inherit
# /type method
# /effect ""
# //parameters
#	definitions
#	inherited
#	boundary
# //returns
{
	my ($this, $definitions, $inherited) = @ARGUMENTS;

	if (@{$this->[ATR_NAMES]})
	{
		if ($_[SPX_BOUNDARY] >= $this->[ATR_LOWEST_INDEX])
		{
			die("($_[SPX_BOUNDARY] >= $this->[ATR_LOWEST_INDEX]) ********************************");
		}
		$_[SPX_BOUNDARY] = $this->[ATR_HIGHEST_INDEX];

		$definitions->add_crosslinks(
			$this->[ATR_META_MONAD]->package_name->value,
			$this->[ATR_NAMES]);

		foreach my $name (@{$this->[ATR_NAMES]})
		{
			if (exists($inherited->{$name}))
			{
				die("Conflicting attribute name '$name'.");
			}
			$inherited->{$name} = IS_EXISTENT;
		}
	}

	$inheritance->call_occupied(
		$this->[ATR_META_MONAD]->parent_classes->perl_isa,
		$inherit,
		$definitions,
		$inherited,
		$_[SPX_BOUNDARY]);
	return;
}

sub set_local_inheritable
# /type method
# /effect ""
# //parameters
#	lowest_index
#	highest_index
#	names
# //returns
{
	my ($this, $lowest_index, $highest_index, $names) = @ARGUMENTS;

	$this->[ATR_LOWEST_INDEX] = $lowest_index;
	$this->[ATR_HIGHEST_INDEX] = $highest_index;
	$this->[ATR_NAMES] = $names;

	$monad_provider->store_monad(
		$this->[ATR_META_MONAD]->package_name->value,
		$this);
	return;
}

#FIXME: should be moved to the RE library
my $constructor_re = q{
	(?:\012|\015\012?)sub\s+
	(?:constructor|attribute_construction) # name (no prototype)
	(?:\012|\015\012?)(?:[^\{\}]+)  # options
	(?:\012|\015\012?)\{(.*?)     # code
	(?:\012|\015\012?)\}
};
my $attribute_re = qr{\[(ATR_\w+)\]};

sub parse_source
# /type method
# /effect ""
# //parameters
#	definitions
# //returns
{
	my ($this, $definitions) = @ARGUMENTS;

	my $meta_monad = $this->[ATR_META_MONAD];
	my $is_ordered = $meta_monad->parent_classes->attribute_type
		->is_type('::Many_Declared::Ordered');
	if (not defined($is_ordered))
	{
#FIXME: this should be removed after migration
		my $pkg_name = $meta_monad->package_name->value;
		$is_ordered = $pkg_name->isa(
			'Carrot::Diversity::Attribute_Type::Many_Declared::Ordered');
	}
	if (not $is_ordered)
	{
		return;
	}

	my $inherited = {};
	my $current_index = ADX_NO_ELEMENTS;
	$this->inherit($definitions, $inherited, $current_index);

	$monad_provider->store_monad(
		$meta_monad->package_name->value,
		$this);

	my $source_code = $meta_monad->source_code;
	return unless ($$source_code =~ m{$constructor_re}sox);

	my $constructor = $1;
	my $local_attributes = [$constructor =~ m{$attribute_re}sogx];
	my $seen = {};
	my $unique_attributes = [];
	foreach my $attribute (@$local_attributes)
	{
		next if (exists($seen->{$attribute}));
		$seen->{$attribute} = IS_EXISTENT;
		push(@$unique_attributes, $attribute);
	}
	$this->[ATR_NAMES] = $unique_attributes;
	$local_attributes = []; # from 'locally used' to 'locally defined'

	$this->[ATR_LOWEST_INDEX] = $current_index+1;
	foreach my $attribute (@$unique_attributes)
	{
		next if (exists($inherited->{$attribute}));

		push(@$local_attributes, $attribute);
		$current_index += 1;
		$definitions->add_constant_function(
			$attribute,
			$current_index);
	}
	$this->[ATR_HIGHEST_INDEX] = $current_index;

	my $code = sprintf(q{$expressiveness->ordered_attributes->set_local_inheritable(%s, %s,
	[qw(%s)]);},
		$this->[ATR_LOWEST_INDEX],
		$this->[ATR_HIGHEST_INDEX],
		join(' ', @$local_attributes));

	$definitions->add_code($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.230
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
