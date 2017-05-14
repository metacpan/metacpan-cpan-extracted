package Carrot::Individuality::Controlled::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MONADS] = IS_UNDEFINED;
	$this->[ATR_MONAD_CLASS] = IS_UNDEFINED;

	return;
}

sub manual_principle
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
#	::Personality::Abstract::Instance
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	my $monads = $this->[ATR_MONADS];
	if (exists($monads->{$pkg_name}))
	{
		return($monads->{$pkg_name});
	}

	return($monads->{$pkg_name} =
		$this->_manual_principle($meta_monad));
}

sub _manual_principle
# /type method
# /effect ""
# /parameters *
# /returns *
{
	return(shift(\@ARGUMENTS)->[ATR_MONAD_CLASS]->indirect_constructor(@ARGUMENTS));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.105
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
