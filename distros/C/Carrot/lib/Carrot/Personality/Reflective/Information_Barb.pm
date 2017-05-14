package Carrot::Personality::Reflective::Information_Barb
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		'Carrot::Personality::Reflective::Information_Barb::',
			my $information_barb_class = '::Step');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_STEPS] = {};
	$this->[ATR_ACTIVE] = IS_UNDEFINED;

	return;
}

sub extend
# /type method
# /effect ""
# //parameters
#	name
#	subject
# //returns
#	?
{
	my ($this, $name, $subject) = @ARGUMENTS;

	if (exists($this->[ATR_STEPS]{$name}))
	{
#FIXME: why the die here?
		die("Attempt to create existing top level chain '$name'.");
#		$hash_key_duplicate->raise_exception(
#			{+HKY_DEX_BACKTRACK => $name,
#			 'key' => $name,
#			 'hash' => '$this->[ATR_STEPS]',
#			 'value' => \$this->[ATR_STEPS]{$name}},
#			ERROR_CATEGORY_SETUP);
	}

	my $step = $information_barb_class->indirect_constructor(
		$subject);

	my $successor = [{%{$this->[ATR_STEPS]}}, $step];
	$successor->[ATR_STEPS]{$name} = $step;

	bless($successor, $this->class_name);
	$successor->lock_attribute_structure;

	if (defined($this->[ATR_ACTIVE]))
	{
		$this->[ATR_ACTIVE]->used;
	}

	return($successor);
}

sub formatted_path_value
# /type method
# /effect ""
# //parameters
#	root
#	path
#	format
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $root, $path, $format) = @ARGUMENTS;

	return('??') unless (exists($this->[ATR_STEPS]{$root}));
	my $step = $this->[ATR_STEPS]{$root};
	return($step->formatted_path_value($path, $format));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.53
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"