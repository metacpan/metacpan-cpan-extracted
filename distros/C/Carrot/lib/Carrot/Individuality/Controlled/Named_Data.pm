package Carrot::Individuality::Controlled::Named_Data
# /type class
# //tabulators
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $inheritance_class = '::Modularity::Object::Inheritance::ISA_Occupancy');
	$expressiveness->package_resolver->provide_name_only(
		my $monad_class = '[=this_pkg=]::Monad');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MONADS] = {};
	$this->[ATR_MONAD_CLASS] = $monad_class;

	my $inheritance = $inheritance_class->indirect_constructor(
		$this->[ATR_MONADS], []);

	$monad_class->load($inheritance);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.65
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"