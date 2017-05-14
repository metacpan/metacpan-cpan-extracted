package Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Scalar./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $class = shift(\@ARGUMENTS);

	my $value = undef;
	my $this = bless(\$value, $class);
	$this->attribute_construction(@ARGUMENTS);
	return($this);
}

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value
# //returns
{
	if (exists($_[SPX_VALUE])) # a compromise; this is the rule
	{
		${$_[THIS]} = $_[SPX_VALUE];
	}
}

sub clone_constructor
# /type method
# /effect "Constructs a new instance with a copied scalar value."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my ($this) = @ARGUMENTS;

	my $value = $$this;
	my $clone = bless(\$value, $this->class_name);
	$clone->_clone_constructor($this) if ($clone->can('_clone_constructor'));
	return($clone);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.99
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
