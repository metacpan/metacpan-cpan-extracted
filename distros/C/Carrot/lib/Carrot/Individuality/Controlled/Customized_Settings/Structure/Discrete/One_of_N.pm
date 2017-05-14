package Carrot::Individuality::Controlled::Customized_Settings::Structure::Discrete::One_of_N
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $iterator_class = '::Personality::Reflective::Iterate::Array::Forward');
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $invalid_definition = 'invalid_definition',
		my $solitary_restriction = 'solitary_restriction',
		my $mismatched_redefinition = 'mismatched_redefinition');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_VALID_VALUES] = [];
	$this->[ATR_SELECTED] = IS_UNDEFINED;

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

	return if (defined($this->[ATR_SELECTED]));
	$this->[ATR_SELECTED] = $that->[ATR_SELECTED];

	return;
}

sub valid_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VALID_VALUES]);
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->selected_value);
}

sub selected_value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return(defined($this->[ATR_SELECTED])
		? $this->[ATR_VALID_VALUES][$this->[ATR_SELECTED]]
		: undef);
}

sub selected_position
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SELECTED]);
}

sub is_empty_selection
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(not defined($_[THIS][ATR_SELECTED]));
}

sub select_position
# /type method
# /effect ""
# //parameters
#	selected
# //returns
{
	$_[THIS][ATR_SELECTED] = $_[SPX_SELECTED];
	return;
}

sub select_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my $iterator = $iterator_class->indirect_constructor($_[THIS][ATR_VALID_VALUES]);
	while ($iterator->advance)
	{
		my ($i, $element) = $iterator->current_index_n_element;
		next unless ($_[SPX_VALUE] eq $element);
		$_[THIS]->select_position($i);
		return;
	}
	return;
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_SELECTED] = IS_UNDEFINED;
	return;
}

#FIXME: duplicates M_of_N
sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	text
# //returns
#	::Personality::Abstract::Boolean
{
	foreach my $value (@{$_[THIS][ATR_VALID_VALUES]})
	{
		return(IS_TRUE) if ($value eq $_[SPX_TEXT]);
	}
	return(IS_FALSE);
}

sub is_selected_value
# /type method
# /effect ""
# //parameters
#	text
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(defined($this->[ATR_SELECTED]) &&
		($this->[ATR_VALID_VALUES][$this->[ATR_SELECTED]]
		eq $_[SPX_TEXT]));
}

sub is_selected_position
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(defined($this->[ATR_SELECTED]) &&
		($this->[ATR_SELECTED] == $_[SPX_POSITION]));
}

sub parse
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	?
{
	unless ($_[SPX_LINE] =~ m{^\s*\((o|_)\)\s+(.+)$}sig)
	{
		$invalid_definition->raise_exception(
			{'line' => $_[SPX_LINE],
			 'example' => "(o) some_setting\n(_) other_setting"},
			ERROR_CATEGORY_SETUP);
	}
	return(lc($1), $2);
}

sub initialize
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	my $selected = IS_UNDEFINED;
	while ($source->advance)
	{
		my ($i, $line) = $source->current_index_n_element;
		my ($flag, $text) = $this->parse($line);

		push($this->[ATR_VALID_VALUES], $text);
		if ($flag eq 'o')
		{
			if (defined($selected))
			{
				$solitary_restriction->raise_exception(
					{'line' => $line,
					'index' => $selected},
					ERROR_CATEGORY_SETUP);
			}
			$this->select_position($i);
			$selected = $i;
		}
	}
	Internals::SvREADONLY(@{$this->[ATR_VALID_VALUES]}, 1);

	return;
}

sub modify
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	$this->clear;
	my $line_count = $source->highest_index;
	if ($line_count == ADX_NO_ELEMENTS)
	{
	} elsif ($line_count == ADX_FIRST_ELEMENT)
	{
		$this->select_value($source->first_element);

	} else {
		$this->set_full($source);
	}
	return;
}

sub set_full
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	my $selected = IS_UNDEFINED;

	while ($source->advance)
	{
		my ($i, $line) = $source->current_index_n_element;

		my ($flag, $text) = $this->parse($line);

		unless ($this->[ATR_VALID_VALUES][$i] eq $text)
		{
			$mismatched_redefinition->raise_exception(
				{'line' => $line,
				 'example' => "($flag) $this->[ATR_VALID_VALUES][$i]"},
				ERROR_CATEGORY_SETUP);
		}
		if ($flag eq 'o')
		{
			if (defined($selected))
			{
				$solitary_restriction->raise_exception(
					{'line' => $line,
					'index' => $selected},
					ERROR_CATEGORY_SETUP);
			}
			$this->select_position($i);
			$selected = $i;
		}
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.105
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"