package Carrot::Productivity::Text::Placeholder::Templague
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $template_class = '::Productivity::Text::Placeholder::Template');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	pkg_names  +multiple ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->[ATR_TEXTS] = [];
	foreach my $argument (@ARGUMENTS)
	{
		push($this->[ATR_TEXTS],
			$template_class->indirect_constructor(@$argument));
	}

	return;
}

sub parser
# /type method
# /effect ""
# //parameters
#	count
#	*
# //returns
#	?
{
	my ($this, $count) = splice(\@ARGUMENTS, 0, 2);
	return($this->[ATR_TEXTS][$count]->parser(@ARGUMENTS));
}

sub add_group
# /type method
# /effect ""
# //parameters
#	count
#	*
# //returns
#	?
{
	my ($this, $count) = splice(\@ARGUMENTS, 0, 2);
	return($this->[ATR_TEXTS][$count]->add_group(@ARGUMENTS));
}

sub compile
# /type method
# /effect ""
# //parameters
#	count
#	*
# //returns
#	?
{
	my ($this, $count) = splice(\@ARGUMENTS, 0, 2);
	return($this->[ATR_TEXTS][$count]->compile(@ARGUMENTS));
}

sub execute
# /type method
# /effect ""
# //parameters
#	count
#	*
# //returns
#	?
{
	my ($this, $count) = splice(\@ARGUMENTS, 0, 2);
	return($this->[ATR_TEXTS][$count]->compile(@ARGUMENTS));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"