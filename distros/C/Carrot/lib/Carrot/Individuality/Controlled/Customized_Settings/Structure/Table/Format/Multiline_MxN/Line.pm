package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Multiline_MxN::Line
# /type class
# //parent_classes
#	[=component_pkg=]::Concise_MxN::Line
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	table_start
# //returns
{
	my ($this, $table_start) = @ARGUMENTS;

	my $lengths = $this->superseded($table_start);
	$this->[ATR_NEXT_MULTIROW] =
		'+'
		.join('+', map(substr(' -' x (int($_/2)+1), 0, $_), @$lengths))
		.'+';
	return;
}

sub is_next_multirow
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_NEXT_MULTIROW]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.94
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"