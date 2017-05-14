package Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar::Class_Default
# /type class
# /capability ""
{
	require 5.8.1;
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Scalar/Class_Default./manual_modularity.pl');
	} #BEGIN

	my $class_defaults = {};

# =--------------------------------------------------------------------------= #

sub clear_class_default
# /type method
# /effect ""
# //parameters
# //returns
{
	delete($class_defaults->{$_[THIS]->class_name});
	return;
}

sub set_class_default
# /type method
# /effect ""
# //parameters
# //returns
{
	$class_defaults->{$_[THIS]->class_name} = $_[SPX_VALUE];
	return;
}

sub reset_to_class_default
# /type method
# /effect ""
# //parameters
# //returns
{
	my $class = $_[THIS]->class_name;
	if (exists($class_defaults->{$class}))
	{
		${$_[THIS]} = $class_defaults->{$class};
	}
	return;
}

sub get_class_default
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $class = $_[THIS]->class_name;
	if (exists($class_defaults->{$class}))
	{
		return($class_defaults->{$class});
	}
	return(IS_UNDEFINED);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
