package Carrot::Individuality::Controlled::Customized_Settings::Structure::List::Plain
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Individuality::Controlled::Customized_Settings::Structure
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $single_type_only = 'single_type_only');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	element
# //returns
{
	my ($this, $element) = @ARGUMENTS;

	$this->[ATR_ELEMENT] = $element;
	$this->[ATR_VALUES] = [];

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
		$this->[ATR_ELEMENT],
		[map($_->clone_constructor, @{$this->[ATR_VALUES]})]
		];
	$this->class_transfer($cloned);
	$cloned->lock_attribute_structure;

	return($cloned);
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VALUES]);
}

sub plain_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([map($_->value, @{$_[THIS][ATR_VALUES]})]);
}

sub cloned_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([map($_->clone_constructor, @{$_[THIS][ATR_VALUES]})]);
}

sub set_element
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	if (defined($_[THIS][ATR_ELEMENT]))
	{
		$single_type_only->raise_exception(
			{'class' => $_[THIS]->class_name},
			ERROR_CATEGORY_SETUP);
	}
	$_[THIS][ATR_ELEMENT] = $_[SPX_ELEMENT];
	return;
}

sub process
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	my $lines = $source->all_elements;
	my $value = $this->[ATR_ELEMENT]->value;
	foreach my $line (@$lines)
	{
		unless ($value->import_textual_value($line))
		{
			die($line);
#			$invalid_value->raise_exception(
#				{'class' => $clone->class_name,
#				'value' => $line},
#				ERROR_CATEGORY_SETUP);
		}
	}
	foreach my $line (@$lines)
	{
		my $clone = $value->clone_constructor;
		$clone->assign_value($line);
		push($this->[ATR_VALUES], $clone);
	}

	return;
}

sub process_clone
# /type method
# /effect ""
# //parameters
#	lines
# //returns
#	?
{
	my ($this, $lines) = @ARGUMENTS;

	if (ref($lines) eq '')
	{
		$lines = [split(
			qr{(\012|\015\012?)}, #ANY_LINE_BREAK
			$lines,
			PKY_SPLIT_RETURN_FULL_TRAIL)];
	}
	my $value = $this->[ATR_ELEMENT]->value;
	foreach my $line (@$lines)
	{
		unless ($value->import_textual_value($line))
		{
			die($line);
#			$invalid_value->raise_exception(
#				{'class' => $clone->class_name,
#				'value' => $line},
#				ERROR_CATEGORY_SETUP);
		}
	}
	my $values = $this->[ATR_VALUES];
	foreach my $line (@$lines)
	{
		my $clone = $value->clone_constructor;
		$clone->assign_value($line);
		push($values, $clone);
	}

	return($values);
}

sub initialize
# /type method
# /effect ""
# //parameters
#	source
# //returns
#	?
{
	return($_[THIS]->process($_[SPX_SOURCE]));
}

sub modify
# /type method
# /effect ""
# //parameters
#	source
# //returns
#	?
{
	return($_[THIS]->process($_[SPX_SOURCE]));
}

sub inherit
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	push($_[THIS][ATR_VALUES], @{$_[THAT][ATR_VALUES]});
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.150
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"