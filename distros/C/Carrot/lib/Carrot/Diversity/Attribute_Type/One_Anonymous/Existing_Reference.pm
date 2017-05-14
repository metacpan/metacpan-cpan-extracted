package Carrot::Diversity::Attribute_Type::One_Anonymous::Existing_Reference
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	require 5.8.1;
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Existing_Reference./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
#	value_ref
#	*
# //returns
#	::Personality::Abstract::Instance
{
	my ($class, $value_ref) = splice(\@ARGUMENTS, 0, 2);

	my $this = bless($value_ref, $class);
	$this->attribute_construction(@ARGUMENTS); # if ($this->can('attribute_construction'));
	$this->lock_attribute_structure;
	return($this);
}

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.74
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
