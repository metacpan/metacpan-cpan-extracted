package Carrot::Diversity::Attribute_Type::Many_Declared::Ordered
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::Many_Declared
# /capability ""
{
	require 5.8.1;
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared/Ordered./manual_modularity.pl');
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

	my $this = bless([], $class);
	$this->attribute_construction(@ARGUMENTS);
	$this->lock_attribute_structure;

	return($this);
}

sub clone_constructor
# /type method
# /effect "Copies all attributes to create a clone."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my ($this) = @ARGUMENTS;

	my $clone = [@$this];
	bless($clone, $this->class_name);
	$clone->_clone_constructor($this) if ($clone->can('_clone_constructor'));
	$clone->lock_attribute_structure;

	return($clone);
}

# sub delivery_constructor
# # /type method
# # /effect "Copies all attributes to create a clone."
# # //parameters
# # //returns
# #	::Personality::Abstract::Instance
# {
# 	my ($class, $this) = @ARGUMENTS;
#
# 	bless($this, $class);
# 	$this->lock_attribute_structure;
#
# 	return($this);
# }
#
# sub recursive_clone_constructor
# # /type method
# # /effect "Recursively calls the method on all attributes to create a clone."
# # //parameters
# # //returns
# #	::Personality::Abstract::Instance
# {
# 	my $cloned = [map($_->recursive_clone_constructor, @{$_[THIS]})];
# 	bless($cloned, $_[THIS]->class_name);
# 	$cloned->lock_attribute_structure;
#
# 	return($cloned);
# }

sub destructor
# /type method
# /effect "Removes the structure of the instance."
# /parameters *
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->attribute_destruction(@ARGUMENTS) if ($this->can('attribute_destruction'));
	$this->unlock_attribute_structure;
	@$this = ();
	$this->lock_attribute_structure;
	return;
}

sub lock_attribute_structure
# /type method
# /effect "Locks the structure of the instance (number of elements)."
# //parameters
# //returns
{
	Internals::SvREADONLY(@{$_[THIS]}, 1);
	return;
}

sub unlock_attribute_structure
# /type method
# /effect "Unlocks the structure of the instance (number of elements)."
# //parameters
# //returns
{
	Internals::SvREADONLY(@{$_[THIS]}, 0);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.131
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
