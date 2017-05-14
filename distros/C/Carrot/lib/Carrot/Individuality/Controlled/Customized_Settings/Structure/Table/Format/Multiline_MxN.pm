package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Multiline_MxN
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate_MxN
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $line_class = '[=this_pkg=]::Line');

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

	for (my $i = ADX_FIRST_ELEMENT; $i <= $#$row; $i++)
	{
		$row->[$i] = $this->unquote_multiline_element($row->[$i], $i);
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

	my $full = IS_UNDEFINED;
	my $context = '';
	while ($cursor->advance)
	{
		if ($line->is_end_body)
		{
			if (defined($full))
			{
				$this->row_action($context, $full);
			}
			last;

		} elsif ($line->is_cut)
		{
			$this->drop_rows;
			$full = IS_UNDEFINED;
			next;

		} elsif ($line->is_next_multirow)
		{
			if (defined($full))
			{
				$this->row_action($context, $full);
			}
			$full = IS_UNDEFINED;
			next;
		}

		my ($type, $elements) = $line->must_be_data;
		if (defined($full))
		{
			unless ($context eq $type)
			{
				die("Context '$context' and start '$type' mismatch");
			}
		} else {
			$context = $type;
			$full = [map([], @$elements)];
		}

		foreach my $i (ADX_FIRST_ELEMENT .. $#$full)
		{
			push($full->[$i], $elements->[$i]);
		}
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.260
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
