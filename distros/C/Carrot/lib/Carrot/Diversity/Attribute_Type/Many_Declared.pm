package Carrot::Diversity::Attribute_Type::Many_Declared
# /type classifier
# //parent_classes
#	::Modularity::Object::Universal
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub re_constructor
# /type method
# /effect ""
# //parameters
#	class
#	*
# //returns
{
	my ($this, $class) = splice(\@ARGUMENTS, 0, 2);

	$this->unlock_attribute_structure;
	$this->class_change($class);
	$this->_re_constructor(@ARGUMENTS) if ($this->can('_re_constructor'));
	$this->lock_attribute_structure;

	return;
}

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.8
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
