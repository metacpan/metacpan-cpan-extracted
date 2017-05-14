package Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar::Access
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Scalar/Access./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub value
# /type method
# /effect "Returns the scalar value of the instance."
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]});
}

sub value_representation_debug
# /type method
# /effect "Returns a representation of the value suitable for debugging."
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]});
}

sub assign_value
# /type method
# /effect "Sets the scalar value of the instance from the argument value."
# //parameters
#	value
# //returns
{
	${$_[THIS]} = $_[SPX_VALUE];
	return;
}

sub assign
# /type method
# /effect "Sets the scalar value of the instance from the argument instance."
# //parameters
#	value
# //returns
{
	${$_[THIS]} = ${$_[THAT]};
	return;
}

sub assign_into_value
# /type method
# /effect "Sets the argument value from the scalar value of the instance."
# //parameters
#	value
# //returns
{
	$_[SPX_VALUE] = ${$_[THIS]};
	return;
}

sub assign_into
# /type method
# /effect "Sets the argument instance from the scalar value of the instance."
# //parameters
#	value
# //returns
{
	${$_[THAT]} = ${$_[THIS]};
	return;
}

sub clone_n_assign_value
# /type method
# /effect "Clones the instance and assigns the argument value to it."
# //parameters
#	value
# //returns
#	::Personality::Abstract::Instance
{
	my $clone = $_[THIS]->clone_constructor;
	$$clone = $_[SPX_VALUE];
	return($clone);
}

sub clone_n_assign
# /type method
# /effect "Clones the instance and assigns the value of the argument instance to it."
# //parameters
#	value
# //returns
#	::Personality::Abstract::Instance
{
	my $clone = $_[THIS]->clone_constructor;
	$$clone = ${$_[THAT]};
	return($clone);
}

sub assign_value_if_undefined
# /type method
# /effect "Assigns from the argument value if the scalar value of the instance is undefined."
# //parameters
#	value
# //returns
{
	${$_[THIS]} //= $_[SPX_VALUE];
	return;
}

sub assign_if_undefined
# /type method
# /effect "Assigns from the argument instance if the scalar value of the instance is undefined."
# //parameters
#	value
# //returns
{
	${$_[THIS]} //= ${$_[THAT]};
	return;
}

sub undefine
# /type method
# /effect "Set the scalar value of the instance to IS_UNDEFINED"
# //parameters
# //returns
{
	${$_[THIS]} = IS_UNDEFINED;
	return;
}

sub is_defined
# /type method
# /effect "Tests whether the instance has a defined scalar value."
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined(${$_[THIS]}));
}

# note there is no "reset", because no room to store what "re" should be
# but see Class_Default.pm
# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.68
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
