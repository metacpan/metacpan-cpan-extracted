package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Concise_MxN::Unique
# /type class
# //parent_classes
#	[=component_pkg=]::Concise_MxN
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $code_evaluation = '::Individuality::Singular::Execution::Code_Evaluation');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this, $names) = @ARGUMENTS;

	$this->superseded;

	$this->[ATR_UNIQUE_INDEX] = {};
	$this->[ATR_INDEX_COLUMNS] = [split(
		',',
		$names,
		PKY_SPLIT_RETURN_FULL_TRAIL)];
	$this->[ATR_INDEX_KEY_CREATOR] = IS_UNDEFINED;

	return;
}

#FIXME: quick hack
my $key_creator_code = q{sub {
	if ($_[0] == 1)
	{
		return(join(chr(1), %s));
	} else {
		return(join(chr(1), %s));
	}
}};
sub parse_lines
# /type method
# /effect ""
# //parameters
#	cursor
#	line
# //returns
{
	my ($this, $cursor, $line) = @ARGUMENTS;

	my $column_index = $this->[ATR_COLUMNS]->names->full_index;

	my $index_positions = [];
	foreach my $name (@{$this->[ATR_INDEX_COLUMNS]})
	{
		push($index_positions, $column_index->{$name});
	}

	my $key_creator = sprintf($key_creator_code,
		join(', ', map("\$_[1][$_]->value", @$index_positions)),
		join(', ', map("\$_[1][$_]", @$index_positions)));
	$code_evaluation->provide_fatally($key_creator);
	$this->[ATR_INDEX_KEY_CREATOR] = $key_creator;

	$this->superseded($cursor, $line);

	return;
}

sub inherit
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	$this->enforce_compatible_structure($that);
	foreach my $row (@{$that->[ATR_ROWS]})
	{
		my $key = $this->[ATR_INDEX_KEY_CREATOR]->(1, $row);
		next if (exists($this->[ATR_UNIQUE_INDEX]{$key}));
		$this->store_row($row);
	}
	return;
}

sub drop_rows
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->superseded;
	$_[THIS][ATR_UNIQUE_INDEX] = {};
	return;
}

sub store_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	my $rows = $this->[ATR_ROWS];
	my $key = $this->[ATR_INDEX_KEY_CREATOR]->(1, $row);
	if (exists($this->[ATR_UNIQUE_INDEX]{$key}))
	{
		my $position = $this->[ATR_UNIQUE_INDEX]{$key};
		splice($rows, $position, 1);
	} else {
		push($rows, $row);
		$this->[ATR_UNIQUE_INDEX]{$key} = $#$rows;
	}

	return;
}

sub delete_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	$this->unquote_row_single($row);

	my $key = $this->[ATR_INDEX_KEY_CREATOR]->(0, $row);
	return unless (exists($this->[ATR_UNIQUE_INDEX]{$key}));
	my $position = delete($this->[ATR_UNIQUE_INDEX]{$key});
	splice($this->[ATR_ROWS], $position, 1);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.159
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
