package Carrot::Modularity::Subroutine::Generator::Scalar_Isset_Methods
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Subroutine/Generator/Scalar_Isset_Methods./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $monad_class = '[=this_pkg=]::Monad');
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub manual_principle
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	meta_monad  ::Meta::Monad::Phase::Begin
# //returns
#	::Personality::Abstract::Instance
{
	return($monad_class->indirect_constructor($_[SPX_META_MONAD]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.142
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
