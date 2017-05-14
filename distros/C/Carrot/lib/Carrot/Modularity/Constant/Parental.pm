package Carrot::Modularity::Constant::Parental
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Parental./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub _add_plugin
# /type method
# /effect ""
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	$package_name->load;
	my $pkg_name = $package_name->value;
	return if (exists($this->[ATR_PLUGIN_NAMES]{$pkg_name}));

	push(@{$this->[ATR_PLUGINS]}, $pkg_name);
	$this->[ATR_PLUGIN_NAMES]{$pkg_name} = IS_EXISTENT;

	return;
}

sub managed_modularity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
#	definitions
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	foreach my $plugin (@{$this->[ATR_PLUGINS]})
	{
		$meta_monad->provide(
			my $monad = $plugin);
		$monad->parse_source($definitions);
	}

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
