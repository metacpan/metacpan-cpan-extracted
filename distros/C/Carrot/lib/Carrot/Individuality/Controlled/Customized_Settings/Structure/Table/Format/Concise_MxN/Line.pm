package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Concise_MxN::Line
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	[=project_pkg=]::Table::Constants
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions =
			'::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $invalid_row_format = 'invalid_row_format');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	table_start
# //returns
#	::Personality::Abstract::Raw::Number
{
	my ($this, $table_start) = @ARGUMENTS;

	unless ($table_start =~ m{^\*.*\*$})
	{
		die("Wrong format of table start: '$table_start'");
	}

	$this->[ATR_LINE] = $table_start;
	my $lengths = [map(length($_), ($table_start =~ m{(-+)}sg))];
	my $table_width = length($table_start);

	$this->[ATR_START_HEAD] = $table_start;
	$this->[ATR_END_HEAD] =
		'+'
		.join('+', map('='x$_, @$lengths))
		.'+';
	$this->[ATR_CUT] =
		'8<'
		.'-'x($table_width-4)
		.'>8';

	my $re =
		'^(\||#|/)'
		.join('\|', map("(.{$_})", @$lengths))
		.'(\||#|/)$';
	$this->[ATR_DATA] = qr{$re};

	return($lengths);
}

sub assign_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	$_[THIS][ATR_LINE] = $_[SPX_VALUE];
	return;
}

sub must_be_data
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $elements = [($this->[ATR_LINE] =~ m{$this->[ATR_DATA]})];

	unless (@$elements)
	{
		$invalid_row_format->raise_exception(
			{'line' => $this->[ATR_LINE],
			 'line_re' => "$this->[ATR_DATA]"},
			ERROR_CATEGORY_SETUP);

	}

	my $start = shift($elements);
	my $end = pop($elements);
	unless ($start eq $end)
	{
		die("Start '$start' doesn't match end '$end'.");
	}

	if ($start eq '|')
	{
		return(RKY_LINE_TABLE_DATA, $elements);

	} elsif ($start eq '/')
	{
		return(RKY_LINE_TABLE_DELETE, $elements);

	} elsif ($start eq '#')
	{
		return(RKY_LINE_TABLE_DEFAULTS, $elements);

	}
	return(IS_UNDEFINED, IS_UNDEFINED);
}

sub is_start_head
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_START_HEAD]);
}

sub is_end_head
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_END_HEAD]);
}

sub is_end_body
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_START_HEAD]);
}

sub is_cut
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][ATR_LINE] eq $_[THIS][ATR_CUT]);
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
