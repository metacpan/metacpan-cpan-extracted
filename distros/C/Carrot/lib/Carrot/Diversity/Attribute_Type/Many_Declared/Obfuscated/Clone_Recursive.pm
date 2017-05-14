package Carrot::Diversity::Attribute_Type::Many_Declared::Obfuscated::Clone_Recursive
# /type class
# /capability ""
{
	warn(__PACKAGE__.' does not work for circular data structures.');

	use strict;
	use warnings 'FATAL' => 'all';
	require Scalar::Util;

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared/Obfuscated/Clone_Recursive./manual_modularity.pl');
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

	my $cloned = {};
	keys(%$this); # reset 'each' iterator
	while (my ($key, $value) = each(%$this))
	{
		if (defined(Scalar::Util::blessed($value)))
		{
			$cloned->{$key} = $value->clone_constructor;
		} else {
			$cloned->{$key} = $value;
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
#	version 1.1.43
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
