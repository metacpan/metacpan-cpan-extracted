package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Concise_MxN
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

sub unquote_element
# /type method
# /effect ""
# //parameters
#	flag
#	element
# //returns
{
	my ($this, $flag, $element) = @ARGUMENTS;

	my $modified = IS_TRUE;
	if ($flag eq q{'})
	{
		$modified = ($element =~ s{'\h*$}{}s);

	} elsif ($flag eq ' ')
	{
		$modified = ($element =~ s{\h*$}{}s);

#		$element =~ s{\\x(\d\d)}{pack('h', $1)}sge;
#		$element =~ s{\u\d{4}}{}sg;
#		$element =~ s{\U\d{8}}{}sg;
#
	} else {
		die("#FIXME: unknown first character '$flag'.");
	}

	if ($modified)
	{
		$_[SPX_ELEMENT] = $element;
	}
	return;
}

sub unquote_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	my $i = ADX_NO_ELEMENTS;
	foreach my $element (@$row)
	{
		$i++;
		$element =~ s{^(.)(.*?)\h*$}{$2}s;
		my $flag = $1;
		next if ($this->resolve_symbolic_element($i, $flag, $element));
		$this->unquote_element($flag, $element);
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

	while ($cursor->advance)
	{
		if ($line->is_end_body)
		{
			last;

		} elsif ($line->is_cut)
		{
			$this->drop_rows;
			next;
		}

		$this->row_action($line->must_be_data);
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.207
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
