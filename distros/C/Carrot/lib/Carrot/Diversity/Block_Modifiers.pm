package Carrot::Diversity::Block_Modifiers
# /type class
# /attribute_type ::Many_Declared::Ordered
# //tabulators
#	::Plugin
# /capability "Provides monads for block modifiers."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader',
		my $plugins = '::Diversity::Block_Modifiers::Plugins');

	my $monad_class = 'Carrot::Diversity::Block_Modifiers::Monad';

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_PLUGINS] = $plugins;
	$this->[ATR_MONADS] = {};

	my $dot_ini = $dot_ini_class->constructor($this);
	$dot_ini->find_configuration;

	$loader->load($monad_class, $this->[ATR_PLUGINS]);

	return;
}

sub dot_ini_got_package_name
# /type method
# /effect "Processes a package name from an .ini file."
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	$this->[ATR_PLUGINS]->add($package_name);

	return;
}

sub manual_principle
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	meta_monad ::Meta::Monad
# //returns
#       ?
{
        my ($this, $meta_monad) = @ARGUMENTS;

        my $pkg_name = $meta_monad->package_name->value;
        my $monads = $this->[ATR_MONADS];
        unless (exists($monads->{$pkg_name}))
        {
		die("Monad for package '$pkg_name' not loaded, yet.");
#               $monads->{$pkg_name} = $monad_class->indirect_constructor;
        }
        return($monads->{$pkg_name});
}

sub managed_diversity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad::Phase::Prepare
#	source
# //returns
{
	my ($this, $meta_monad, $source) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	if (exists($this->[ATR_MONADS]{$pkg_name}))
	{
		die("A monad for package '$pkg_name' already exists.");
	}

	my $monad = $monad_class->constructor($source);
	$this->[ATR_MONADS]{$pkg_name} = $monad;
	$monad->managed_diversity($meta_monad, $source);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.118
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"