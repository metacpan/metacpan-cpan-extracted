package Carrot::Modularity::Constant::Local
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Local./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

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
		$plugin->constants_definitions(
			$meta_monad,
			$definitions);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.116
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
