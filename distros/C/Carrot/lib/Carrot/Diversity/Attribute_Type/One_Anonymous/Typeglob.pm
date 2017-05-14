package Carrot::Diversity::Attribute_Type::One_Anonymous::Typeglob
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Typeglob./manual_modularity.pl');
	} #BEGIN

	require Symbol;

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $this = Symbol::gensym;
	bless($this, shift(\@ARGUMENTS));
	$this->attribute_construction(@ARGUMENTS); # if ($this->can('attribute_construction'));
	return($this);
}

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
#	?
{
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.71
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
