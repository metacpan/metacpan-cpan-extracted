package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Aggregated_MxOxN
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $line_class = '[=this_pkg=]::Line');

	sub IDX_ROW_M()   { 0 }
	sub IDX_ROW_OXN() { 1 }

# =--------------------------------------------------------------------------= #

sub table_line_constructor
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
#	first_line
# //returns
#	::Personality::Abstract::Instance
{
	return($line_class->indirect_constructor($_[SPX_FIRST_LINE]));
}

sub unquote_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	$row->[ADX_FIRST_ELEMENT] = $this->unquote_multiline_element(
		$row->[ADX_FIRST_ELEMENT], ADX_FIRST_ELEMENT);

	foreach my $subrow (@{$row->[ADX_SECOND_ELEMENT]})
	{
		$subrow->[ADX_FIRST_ELEMENT] = undef;
		for (my $i = ADX_SECOND_ELEMENT; $i <= $#$subrow; $i++)
		{
			$subrow->[$i] = $this->unquote_multiline_element(
				$subrow->[$i], $i);
		}
	}

	return;
}

sub parse_lines
# /type method
# /effect ""
# //parameters
#	cursor
#	line
# //returns
{
	my ($this, $cursor, $line) = @ARGUMENTS;

	my $one_xoxn = IS_UNDEFINED;
	my $oxn = IS_UNDEFINED;
	my $context = '';
	my ($type, $elements);
	while ($cursor->advance)
	{
		if ($line->is_end_body)
		{
			if (defined($one_xoxn))
			{
				$this->row_action($context, $one_xoxn);
			}
			last;

		} elsif ($line->is_cut)
		{
			$this->drop_rows;
			$one_xoxn = IS_UNDEFINED;
			next;

		} elsif (my $element = $line->is_next_subrow)
		{
			unless (defined($one_xoxn))
			{
				die("Can't start next subrow without an initial subrow.");
			}
			push($one_xoxn->[0], $element);
			$oxn = [map([], @$elements)];
			push($one_xoxn->[1], $oxn);
			next;

		} elsif ($line->is_next_row)
		{
			if (defined($one_xoxn))
			{
				$this->row_action($context, $one_xoxn);
			}
			$one_xoxn = IS_UNDEFINED;
			next;
		}

		($type, $elements) = $line->must_be_data;
		if (defined($one_xoxn))
		{
			unless ($context eq $type)
			{
				die("Context '$context' and start '$type' mismatch");
			}
		} else {
			$context = $type;
			$oxn = [map([], @$elements)];
			$one_xoxn = [[], [$oxn]];
		}

		push($one_xoxn->[0], $elements->[0]);
		foreach my $i (1 .. $#$oxn)
		{
			push($oxn->[$i], $elements->[$i]);
		}
	}
	return;
}

sub add_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	my $columns = $this->[ATR_COLUMNS];

	$row->[ADX_FIRST_ELEMENT] = $columns->process_clone(ADX_FIRST_ELEMENT,
		$row->[ADX_FIRST_ELEMENT]);

	foreach my $subrow (@{$row->[ADX_SECOND_ELEMENT]})
	{
#		$subrow->[ADX_FIRST_ELEMENT] = $row->[ADX_FIRST_ELEMENT];
		for (my $i = ADX_SECOND_ELEMENT; $i <= $#$subrow; $i++)
		{
			$subrow->[$i] = $columns->process_clone($i,
				$subrow->[$i]);
		}
	}
	$this->store_row($row);

	return;
}

sub delete_row
# /type method
# /effect ""
# //parameters
#	row1
# //returns
{
	my ($this, $row1) = @ARGUMENTS;

	my $delete = [];
	unless (defined($row1->[0]))
	{
		die("Can only delete based on the aggregated value.");
	}
	my $i = ADX_NO_ELEMENTS;
	foreach my $row (@{$this->[ATR_ROWS]})
	{
		$i++;
		next if ($row->[0] ne $row1->[0]);
		push($delete, $i);
	}
	foreach my $i (@$delete)
	{
		splice($this->[ATR_ROWS], $i, 1);
	}

	return;
}

sub first_column
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Raw::Array
{
	return([map($_->[ADX_FIRST_ELEMENT], @{$_[THIS][ATR_ROWS]})]);
}

sub first_column_plain
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Raw::Array
{
	return([map($_->[ADX_FIRST_ELEMENT]->value, @{$_[THIS][ATR_ROWS]})]);
}

sub provide_row
# /type method
# /effect ""
# //parameters
#	named_value  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $named_value (@ARGUMENTS)
	{
		foreach my $row (@{$this->[ATR_ROWS]})
		{
			next if ($row->[IDX_ROW_M]->value ne $named_value);
			$named_value = $row;
			last;
		}
		if (ref($named_value) eq '')
		{
			die("No row with aggregated key '$named_value' found.");
		}
	}

	return;
}

sub row_1xN
# /type method
# /effect ""
# //parameters
#	key
#	name
# //returns
#	?
{
	my ($this, $key, $name) = @ARGUMENTS;

	$this->provide_row($key);
	my $i = $this->[ATR_COLUMNS]->index($name);
	return([map($_->[$i], @{$key->[IDX_ROW_OXN]})]);
}

sub row_1xN_merged
# /type method
# /effect ""
# //parameters
#	key
#	name
# //returns
#	?
{
	my ($this, $keys, $name) = @ARGUMENTS;

	my $i = $this->[ATR_COLUMNS]->index($name);
	my $column = [];
	foreach my $key (@$keys)
	{
		$this->provide_row($key);
		push($column, map($_->[$i], @{$key->[IDX_ROW_OXN]}))
	}

	return($column);
}

sub row_OxN
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this, $key, $name) = @ARGUMENTS;

	$this->provide_row($key);
	return([@{$key->[IDX_ROW_OXN]}]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.330
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
