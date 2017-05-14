package Carrot::Individuality::Controlled::Customized_Settings::Definition::Table
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $values_class = '[=project_pkg=]::Structure::Flat::Plain');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	structure
# //returns
{
	my ($this, $structure) = @ARGUMENTS;

	$this->superseded($structure);

	$this->[ATR_STRUCTURE_SOURCE] = IS_UNDEFINED;
	$this->[ATR_COLUMNS] = [];

	return;
}

sub implement
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if (defined($this->[ATR_SOURCE]))
	{
		$this->[ATR_COLUMNS][ADX_LAST_ELEMENT]
			->initialize($this->[ATR_SOURCE]);
		$this->[ATR_SOURCE] = IS_UNDEFINED;
	}
	$this->[ATR_STRUCTURE]->set_columns($this->[ATR_COLUMNS]);

	if (defined($this->[ATR_STRUCTURE_SOURCE]))
	{
		$this->[ATR_STRUCTURE]->initialize(
			$this->[ATR_STRUCTURE_SOURCE]);
		$this->[ATR_STRUCTURE_SOURCE] = IS_UNDEFINED;
	}

	return($this->[ATR_STRUCTURE]);
}

sub add_column
# /type method
# /effect ""
# //parameters
#	column
# //returns
#	?
{
	my ($this, $column) = @ARGUMENTS;

	if ($column->can('import_textual_value'))
	{
		$column = $values_class->indirect_constructor($column);
	}

	if ($#{$this->[ATR_COLUMNS]} == ADX_NO_ELEMENTS)
	{
		$this->[ATR_STRUCTURE_SOURCE] = $this->[ATR_SOURCE];
		$this->[ATR_SOURCE] = IS_UNDEFINED;

	} elsif (defined($this->[ATR_SOURCE]))
	{
		$this->[ATR_COLUMNS][ADX_LAST_ELEMENT]
			->initialize($this->[ATR_SOURCE]);
		$this->[ATR_SOURCE] = IS_UNDEFINED;
	}

	push($this->[ATR_COLUMNS], $column);
	return($column);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.98
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"