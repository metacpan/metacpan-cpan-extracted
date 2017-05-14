package Carrot::Individuality::Controlled::Class_Names
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
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini',
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
	$this->[ATR_CONFIG] = {};

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	my $universal = []; #FIXME: fill with life
	my $inheritance = $inheritance_class->indirect_constructor(
		$this->[ATR_MONADS], $universal);

	$monad_class->load($inheritance);

	return;
}

sub dot_ini_got_section
# /type method
# /effect "Processes a section from an .ini file."
# //parameters
#	name
#	lines
# //returns
{
	my ($this, $name, $lines) = @ARGUMENTS;

	my $config = $this->[ATR_CONFIG];
	unless (exists($config->{$name}))
	{
		$config->{$name} = [];
	}
	push($config->{$name}, @$lines);

	return;
}

sub _manual_principle
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
#	?
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;

	my $mapping = {};
	if (exists($this->[ATR_CONFIG]{$pkg_name}))
	{
		my $lines = delete($this->[ATR_CONFIG]{$pkg_name});
		foreach my $line (@$lines)
		{
			my ($key, $value) = split(qr{\h+}, $line, 2);
			$mapping->{$key} = $value;
		}
	}
	my $monad = $monad_class->indirect_constructor(
		$meta_monad,
		$mapping);

	return($monad);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.99
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Truemper <win@carrot-programming.org>"