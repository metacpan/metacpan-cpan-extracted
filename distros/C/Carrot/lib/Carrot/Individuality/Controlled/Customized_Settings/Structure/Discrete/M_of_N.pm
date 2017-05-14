package Carrot::Individuality::Controlled::Customized_Settings::Structure::Discrete::M_of_N
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
		my $mismatched_redefinition = 'mismatched_redefinition');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	name
# //returns
{
	my ($this, $name) = @ARGUMENTS;

	$this->[ATR_VALID_VALUES] = [];
	$this->[ATR_SELECTED] = [];

	return;
}

sub clone_constructor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $cloned = [
		$this->[ATR_VALID_VALUES],
		[@{$this->[ATR_SELECTED]}]
		];
	bless($cloned, $this->class_name);
	$cloned->lock_attribute_structure;

	return($cloned);
}

sub inherit
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	die;
} # no straightforward meaning, would require tristate checkbox

sub valid_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VALID_VALUES]);
}

sub selected_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $valid_values = $this->[ATR_VALID_VALUES];
	my $selected_values = [];

	my $iterator = $iterator_class->indirect_constructor(
		$this->[ATR_SELECTED]);
	while ($iterator->advance)
	{
		my ($i, $flag) = $iterator->current_index_n_element;
		next unless ($flag);
		push($selected_values, $valid_values->[$i]);
	}
	return(@$selected_values);
}

sub is_empty_selection
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my $sum = 0;
	foreach (@{$_[THIS][ATR_SELECTED]})
	{
		$sum += $_;
	}
	return(($sum == 0));
}

sub select_position
# /type method
# /effect ""
# //parameters
#	selected
# //returns
{
	$_[THIS][ATR_SELECTED][$_[SPX_SELECTED]] = IS_TRUE;
	return;
}

sub deselect_position
# /type method
# /effect ""
# //parameters
#	selected
# //returns
{
	$_[THIS][ATR_SELECTED][$_[SPX_SELECTED]] = IS_FALSE;
	return;
}

sub select_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my $iterator = $iterator_class->indirect_constructor(
		$_[THIS][ATR_VALID_VALUES]);
	while ($iterator->advance)
	{
		my ($i, $element) = $iterator->current_index_n_element;
		next unless ($_[SPX_VALUE] eq $element);
		$_[THIS]->select_position($i);
		return;
	}
	return;
}

sub deselect_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my $iterator = $iterator_class->indirect_constructor(
		$_[THIS][ATR_VALID_VALUES]);
	while ($iterator->advance)
	{
		my ($i, $element) = $iterator->current_index_n_element;
		next unless ($_[SPX_VALUE] eq $element);
		$_[THIS]->deselect_position($i);
		return;
	}
	return;
}

sub deselect_all
# /type method
# /effect ""
# //parameters
# //returns
{
	map($_ = IS_FALSE, @{$_[THIS][ATR_SELECTED]});
	return;
}

sub select_all
# /type method
# /effect ""
# //parameters
# //returns
{
	map($_ = IS_TRUE, @{$_[THIS][ATR_SELECTED]});
	return;
}

#FIXME: was contains_element before
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
	my ($this, $text) = @ARGUMENTS;

	my $valid_values = $this->[ATR_VALID_VALUES];
	foreach my $position (@{$_[THIS][ATR_SELECTED]})
	{
		return(IS_TRUE) if ($valid_values->[$position] eq $_[SPX_TEXT]);
	}
	return(IS_FALSE);
}

sub parse
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	?
{
	unless ($_[SPX_LINE] =~ m{^\s*\[(x|_)\]\s+(.+)$}sig)
	{
		$invalid_definition->raise_exception(
			{'line' => $_[SPX_LINE],
			 'example' => "[x] some_setting\n[_] other_setting"},
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

	while ($source->advance)
	{
		my $line = $source->current_element;
		my ($flag, $text) = $this->parse($line);

		push($this->[ATR_VALID_VALUES], $text);
		push($this->[ATR_SELECTED],
			(($flag eq 'x') ? IS_TRUE : IS_FALSE));
	}
	Internals::SvREADONLY(@{$this->[ATR_VALID_VALUES]}, 1);
	Internals::SvREADONLY(@{$this->[ATR_SELECTED]}, 1);

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

	my $iterator = $iterator_class->indirect_constructor(
		$this->[ATR_VALID_VALUES]);

LINE:	while ($source->advance)
	{
		my $line = $source->current_element;
		my ($flag, $text) = $this->parse($line);

		my $action = ($flag eq 'x')
			? 'select_position'
			: 'deselect_position';
		if ($text eq '*')
		{
			if ($action eq 'deselect')
			{
				$this->deselect_all;
			} else {
				$this->select_all;
			}
			next;
		}

		$iterator->reset;
		while ($iterator->advance)
		{
			my ($i, $member) = $iterator->current_index_n_element;
			next unless ($text eq $member);
			$this->$action($i);
			next LINE;
		}

		$mismatched_redefinition->raise_exception(
			{'line' => $line,
			 'example' => "[$flag] some_setting_from_original_definition"},
			ERROR_CATEGORY_SETUP);
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