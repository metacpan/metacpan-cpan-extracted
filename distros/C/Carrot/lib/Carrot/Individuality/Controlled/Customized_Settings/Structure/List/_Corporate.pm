package Carrot::Individuality::Controlled::Customized_Settings::Structure::List::_Corporate
# /type class
# /instances none
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
		$this->cloned_values
		];
	$this->class_transfer($cloned);
	$cloned->lock_attribute_structure;

	return($cloned);
}

sub values
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
	return([map($_->get_value, @{$_[THIS][ATR_VALUES]})]);
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

sub populate
# /type method
# /effect ""
# //parameters
#	raw_data
# //returns
{
	my ($this, $raw_data) = @ARGUMENTS;

	foreach my $element (@$raw_data)
	{
		my $clone = $this->[ATR_ELEMENT]->clone_constructor;
		my $problem = $this->[ATR_VARIATIONS]
			->apply_modification(
				$this,
				$clone,
				$this->[ATR_INITIALIZED],
				$element);

		if (defined($problem))
		{
			my $consequence = $this->[ATR_ON_FAILURE][$this->[ATR_INITIALIZED]];
			if ($consequence == NCV_CSQ_IGNORE)
			{
			} elsif ($consequence == NCV_CSQ_WARN)
			{
				warn($problem);
			}
			die($problem, $this->[ATR_INITIALIZED]);
		}

		push($this->[ATR_VALUES], $clone);
	}
	unless ($this->[ATR_INITIALIZED])
	{
		$this->[ATR_INITIALIZED] = IS_TRUE;
	}

	return;
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
#	version 1.1.110
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"