package Carrot::Individuality::Singular::Execution::STDERR_Redirector
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini',
		'::Individuality::Singular::Execution::STDERR_Redirector::',
			my $monad_class = '::Monad');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_REDIRECTIONS] = {};
	$this->[ATR_PACKAGES] = {};

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	return;
}

sub dot_ini_got_association
# /type method
# /effect "Processes an association from an .ini file."
# /parameters *
# //returns
{
	shift(\@ARGUMENTS)->add_redirection(@ARGUMENTS);
	return;
}

sub add_redirection
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $pkg_name, $file_name) = @ARGUMENTS;

	$this->[ATR_REDIRECTIONS]{$pkg_name} = $file_name;

	return;
}

sub manual_individuality
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	meta
# //returns
#	?
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	my $packages = $this->[ATR_PACKAGES];
	if (exists($packages->{$pkg_name}))
	{
		return($packages->{$pkg_name});
	}

	foreach my $pkg_name (@{$meta_monad->parents})
	{
		next unless (exists($packages->{$pkg_name}));
		return($packages->{$pkg_name});
	}

	my $monad = $monad_class->indirect_constructor(
		$this->[ATR_REDIRECTIONS]{$pkg_name});

	$packages->{$pkg_name} = $monad;
	return($monad);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.70
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"