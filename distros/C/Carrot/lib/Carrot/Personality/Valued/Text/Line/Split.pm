package Carrot::Personality::Valued::Text::Line::Split
# /type class
# //parent_classes
#	::Personality::Valued::Text::Line::Classified,
#	::Personality::Elemental::Scalar::Textual
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


	#FIXME: the split_* methods are leftovers
# =--------------------------------------------------------------------------= #

sub split_at_separator
# /type method
# /effect ""
# //parameters
#	separator
# //returns
#	?
{
	return(split($_[SPX_SEPARATOR], ${$_[THIS]}));
}

sub split_at_white_space
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(split(m{\h+}, ${$_[THIS]}));
}

sub split_at_commas
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(split(m{\h*,\h*}, ${$_[THIS]}));
}

sub split_at_colons
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(split(m{\h*\:\h*}, ${$_[THIS]}));
}

sub split_at_semicolons
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(split(m{\h*;\h*}, ${$_[THIS]}));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.58
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
