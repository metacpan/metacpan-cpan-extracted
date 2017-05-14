package Carrot::Individuality::Controlled::Customized_Settings::Source::Here::Plain
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Personality::Reflective::Iterate::Array::Forward
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	lines
# //returns
{
	$_[THIS]->superseded($_[SPX_LINES] // []);
#	$_[THIS][ATR_ELEMENTS]

	return;
}

sub append_element
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	push($_[THIS][ATR_ELEMENTS], $_[SPX_ELEMENT]);
	return;
}

sub as_text
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(join(TXT_LINE_BREAK, @{$_[THIS][ATR_ELEMENTS]}));
}

sub as_text_ref
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $buffer = join(TXT_LINE_BREAK, @{$_[THIS][ATR_ELEMENTS]});
	return(\$buffer);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.79
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
