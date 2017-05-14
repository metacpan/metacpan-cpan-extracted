package Carrot::Productivity::Text::Placeholder::Miniplate::Information_Barb
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $subject_class = '::Personality::Reflective::Information_Barb');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	subject
# //returns
{
	my ($this, $subject) = @ARGUMENTS;

	$this->[ATR_SUBJECT] = $subject_class->indirect_constructor;

	return;
}

sub set_subject
# /type method
# /effect ""
# //parameters
#	subject
# //returns
{
	$_[THIS][ATR_SUBJECT] = $_[SPX_SUBJECT];
	return;
}

sub get_placeholder_value
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	# level of indirection because a $subject comes very late - if ever
	return(shift(\@ARGUMENTS)->[ATR_SUBJECT]->formatted_path_value(@ARGUMENTS));
}
my $get_placeholder_value = \&get_placeholder_value;

sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	my ($this, $placeholder) = @ARGUMENTS;

	return(IS_UNDEFINED) unless ($placeholder =~ s{^(.+?)\.}{});
	my $root = $1;
	my $format = (($placeholder =~ s{\@(.+)$}{}) ? $1 : undef);

	return([$get_placeholder_value, [$this, $root, $placeholder, $format]]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.54
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"