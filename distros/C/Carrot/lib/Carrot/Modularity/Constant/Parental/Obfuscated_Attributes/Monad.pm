package Carrot::Modularity::Constant::Parental::Obfuscated_Attributes::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	monad_provider  ::Modularity::Constant::Parental::Obfuscated_Attributes
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability ""
{
	my ($monad_provider, $inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Parental/Obfuscated_Attributes/Monad./manual_modularity.pl');
	} #BEGIN

	my $used_keys = {};

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

	return;
}

my $inherit = \&inherit;
sub inherit
# /type method
# /effect ""
# //parameters
#	definitions
#	inherited
# //returns
{
	my ($this, $definitions, $inherited) = @ARGUMENTS;

	if (@{$this->[ATR_NAMES]})
	{
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
		$definitions);
	return;
}

sub set_local_inheritable
# /type method
# /effect ""
# //parameters
#	names
#	used_keys
# //returns
{
	my ($this, $names, $used_keys) = @ARGUMENTS;

	$this->[ATR_NAMES] = $names;
	foreach my $key (@$used_keys)
	{
		$used_keys->{$key} = IS_EXISTENT;
	}

	$monad_provider->store_monad(
		$this->[ATR_META_MONAD]->package_name->value,
		$this);
	return;
}

sub unique_random_hex
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $name) = @ARGUMENTS;

	my $key;
	while (IS_TRUE)
	{
		$key = sprintf('%08x', int(rand(2**31-1)));
		last unless (exists($used_keys->{$key}));
	}
	$used_keys->{$key} = $name;
	return($key);

}

my $constructor_re = q{
	(?:\012|\015\012?)sub\h+
	(constructor|attribute_construction) # name (no prototype)
	(?:\012|\015\012?)(?:[^\{\}]+)  # options
	(?:\012|\015\012?)\{(.*?)     # code
	(?:\012|\015\012?)\}
};
my $attribute_re = qr{\{(ATR_\w+)\}};

sub parse_source
# /type method
# /effect ""
# //parameters
#	definitions
# //returns
{
	my ($this, $definitions) = @ARGUMENTS;

#FIXME: hasn't been used for a long time
	return;
	my $meta_monad = $this->[ATR_META_MONAD];
	my $is_obfuscated = $meta_monad->parent_classes->attribute_type
		->is_type('::Many_Declared::Obfuscated');
	if (not defined($is_obfuscated))
	{
		my $pkg_name = $meta_monad->package_name->value;
		$is_obfuscated = $pkg_name->isa('Carrot::Diversity::Attribute_Type::Many_Declared::Obfuscated');
	}
	if (not $is_obfuscated)
	{
		return;
	}
	my $inherited = {};
	$this->inherit($definitions, $inherited);

	my $source_code = $meta_monad->source_code->as_text;
	return unless ($$source_code =~ m{$constructor_re}sox);
	my $constructor = $1;

	my $local_attributes = [$constructor =~ m{$attribute_re}sogx];
	unless (@$local_attributes)
	{
		my $pkg_name = $meta_monad->package_name->value;
		die("Constructor without attributes in package '$pkg_name' is suspicious.");
	}
	my $seen = {};
	my $unique_attributes = [];
	foreach my $attribute (@$local_attributes)
	{
		next if (exists($seen->{$attribute}));
		$seen->{$attribute} = IS_EXISTENT;
		push(@$unique_attributes, $attribute);
	}
	$this->[ATR_NAMES] = $unique_attributes;
	$local_attributes = [];

	my $used_keys = {};
	foreach my $attribute (@$unique_attributes)
	{
		next if (exists($inherited->{$attribute}));

		push(@$local_attributes, $attribute);
		my $key = $this->unique_random_hex($attribute);
		$definitions->add_constant_function(
			$attribute,
			$key);
		$used_keys->{$key} = IS_EXISTENT;
	}

	$monad_provider->store_monad(
		$meta_monad->package_name->value,
		$this);
	my $code = sprintf(q{
$expressiveness->obfuscated_attributes->set_local_inheritable(
	[qw(%s)],
	[qw(%s)]);
},
		join(' ', @$local_attributes),
		join(' ', @$used_keys));
	$definitions->add_code($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.180
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"