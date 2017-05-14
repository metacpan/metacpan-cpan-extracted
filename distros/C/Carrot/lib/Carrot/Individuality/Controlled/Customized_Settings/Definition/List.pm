package Carrot::Individuality::Controlled::Customized_Settings::Definition::List
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		'[=project_pkg=]::Structure::',
	#		my $list_class = '::List::Plain',
			my $values_class = '::Flat::Plain');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	structure
# //returns
{
	my ($this, $structure) = @ARGUMENTS;

#	my $element = IS_UNDEFINED;
#	if (!$structure->isa('Carrot::Individuality::Controlled::Customized_Settings::Structure'))
#	{
#		$element = $structure;
#		$structure = $list_class->indirect_constructor;
#
#	}
	$this->superseded($structure);

	$this->[ATR_STRUCTURE_SOURCE] = IS_UNDEFINED;
	$this->[ATR_ELEMENT] = IS_UNDEFINED;

#	if (defined($element))
#	{
#		$this->set_element($element);
#	}
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
		$this->[ATR_ELEMENT]->initialize($this->[ATR_SOURCE]);
		$this->[ATR_SOURCE] = IS_UNDEFINED;
	}

	if (defined($this->[ATR_STRUCTURE_SOURCE]))
	{
		$this->[ATR_STRUCTURE]->initialize(
			$this->[ATR_STRUCTURE_SOURCE]);
		$this->[ATR_STRUCTURE_SOURCE] = IS_UNDEFINED;
	}

	return($this->[ATR_STRUCTURE]);
}

sub set_element
# /type method
# /effect ""
# //parameters
#	element
# //returns
{
	my ($this, $element) = @ARGUMENTS;

	if (!$element->isa('Carrot::Individuality::Controlled::Customized_Settings::Structure'))
	{
		$element = $values_class->indirect_constructor($element);
	}
	$this->[ATR_STRUCTURE_SOURCE] = $this->[ATR_SOURCE];
	$this->[ATR_SOURCE] = IS_UNDEFINED;

	$this->[ATR_STRUCTURE]->set_element($element);
	$this->[ATR_ELEMENT] = $element;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.117
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"