package Carrot::Modularity::Constant::Parental::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Parental/_Corporate./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub managed_modularity
# /type method
# /effect "Returns an individual monad for a package."
# /alias_name manual_modularity
# //parameters
#	meta_monad ::Meta::Monad
# //returns
#	::Personality::Abstract::Instance
{
        my ($this, $meta_monad) = @ARGUMENTS;

        return($this->[ATR_MONAD_CLASS]
		->indirect_constructor($meta_monad));
}
*manual_modularity = \&managed_modularity;

sub store_monad
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	pkg_name
#	monad
# //returns
#       ?
{
        my ($this, $pkg_name, $monad) = @ARGUMENTS;

	if (OPTIMIZE_FLAG)
	{
#FIXME: this requires an option to overwrite /is_parent
#FIXME: this is ancient code
#		my $options = $meta_monad->source_code->block_options('package');
#		return if (exists($options->->{'is_parent'}));
	}
	$this->[ATR_MONADS]{$pkg_name} = $monad;

        return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.96
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
