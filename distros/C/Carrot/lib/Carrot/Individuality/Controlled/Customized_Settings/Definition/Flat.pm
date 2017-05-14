package Carrot::Individuality::Controlled::Customized_Settings::Definition::Flat
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

	if (!$structure->isa('Carrot::Individuality::Controlled::Customized_Settings::Structure'))
	{
		$structure = $values_class->indirect_constructor($structure);
	}
	$this->superseded($structure);

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
		$this->[ATR_STRUCTURE]->initialize($this->[ATR_SOURCE]);
		$this->[ATR_SOURCE] = IS_UNDEFINED;
	}
	return($this->[ATR_STRUCTURE]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.90
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"