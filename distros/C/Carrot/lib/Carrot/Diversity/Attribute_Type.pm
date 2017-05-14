package Carrot::Diversity::Attribute_Type
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader');

	my $valid_types = {
		'::One_Anonymous::Scalar' => IS_EXISTENT,
		'::One_Anonymous::Scalar::Access' => IS_EXISTENT,
		'::One_Anonymous::Array' => IS_EXISTENT,
		'::One_Anonymous::Hash' => IS_EXISTENT,
		'::Many_Declared::Obfuscated' => IS_EXISTENT,
		'::Many_Declared::Ordered' => IS_EXISTENT,
		'::One_Anonymous::Existing_Reference' => IS_EXISTENT,
		'::One_Anonymous::Regular_Expression' => IS_EXISTENT,
		'::One_Anonymous::Typeglob' => IS_EXISTENT,
	};
	my $root_class = 'Carrot::Diversity::Attribute_Type';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	parent_classes  ::Modularity::Object::Parent_Classes::Monad
# //returns
{
	my ($this, $parent_classes) = @ARGUMENTS;

	$this->[ATR_PARENT_CLASSES] = $parent_classes;
	$this->[ATR_TYPE] = IS_UNDEFINED;

	return;
}

sub is_type
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $value) = @ARGUMENTS;

	return(IS_UNDEFINED) unless (defined($this->[ATR_TYPE]));
	return($this->[ATR_TYPE] eq $value);
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_TYPE]);
}

sub assign
# /type method
# /effect ""
# //parameters
#	pkg_name       ::Personality::Abstract::Text
# //returns
{
	my ($this, $pkg_name) = @ARGUMENTS;

	unless (exists($valid_types->{$pkg_name}))
	{
		die("Attribute type '$pkg_name' isn't valid.");
	}
	if (defined($this->[ATR_TYPE]))
	{
		unless ($this->[ATR_TYPE] eq $pkg_name)
		{
			die("Attempt to re-set the attribute type to an incompatible value '$pkg_name'.");
		}
	} else {
		$this->[ATR_TYPE] = $pkg_name;
		my $qualified = "$root_class$pkg_name";
		$loader->load($qualified);
		$this->[ATR_PARENT_CLASSES]->add_qualified($qualified);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.217
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
