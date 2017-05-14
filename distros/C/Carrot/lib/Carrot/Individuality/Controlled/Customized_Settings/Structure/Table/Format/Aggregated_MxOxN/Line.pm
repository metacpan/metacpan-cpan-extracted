package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Aggregated_MxOxN::Line
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

	my $subrow_re =
		'^\|(.{'
		.$lengths->[0]
		.'})\+'
		.join('\+', map(substr(' -' x (int($_/2)+1), 0, $_),
			@$lengths[1..$#$lengths]))
		.'\+$';
	$this->[ATR_NEXT_SUBROW] = qr{$subrow_re};
	$this->[ATR_NEXT_ROW] =
		'+'
		.join('+', map('-'x$_, @$lengths))
		.'+';

	return;
}

sub is_next_subrow
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	# duplicates ->matched_groups somehow
	my $elements = [$this->[ATR_LINE] =~ m{$this->[ATR_NEXT_SUBROW]}];
	if (@$elements)
	{
		return($elements->[ADX_FIRST_ELEMENT]);
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_next_row
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	?
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_NEXT_ROW]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.109
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"