package Carrot::Diversity::Attribute_Type::Many_Declared::Ordered::Clone_Recursive
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared/Ordered/Clone_Recursive./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub clone_constructor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $cloned = [];
	foreach my $attribute (@$this)
	{
		if (defined(Scalar::Util::blessed($attribute)))
		{
			push($cloned, $attribute->clone_constructor);
		} else {
			push($cloned, $attribute);
		}
	}

	$this->class_transfer($cloned);
	$cloned->lock_attribute_structure;

	return($cloned);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
