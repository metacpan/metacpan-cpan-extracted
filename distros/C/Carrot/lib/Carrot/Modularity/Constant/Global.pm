package Carrot::Modularity::Constant::Global
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub default_plugin_autoload
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	#NOTE: global constants are simple, allowing for recursion
	return(Scalar::Util::blessed($_[THIS]).'::**');
}

sub add_plugin
# /type method
# /effect ""
# //parameters
#	plugin_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $plugin_name) = @ARGUMENTS;

	$plugin_name->load;
	next if ($plugin_name->is_supportive);

	my $plugin_pkg = $plugin_name->value;
	my $added = $this->add_re_pattern($plugin_pkg, $plugin_name);
	if ($added)
	{
		push($this->[ATR_PLUGIN_NAMES], $plugin_pkg);
	}
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

	my $source_code = $meta_monad->source_code;
	foreach my $pkg_name (@{$this->[ATR_PLUGIN_NAMES]})
	{
		my $symbols = $source_code->unique_matches(
			$this->[ATR_PATTERNS]{$pkg_name});

		next if ($#$symbols == ADX_NO_ELEMENTS);
		$definitions->add_crosslinks($pkg_name, $symbols);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.172
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
