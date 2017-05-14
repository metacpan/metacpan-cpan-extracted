package Carrot::Individuality::Controlled::Distinguished_Exceptions
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# //tabulators
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $localized_messages = '::Individuality::Controlled::Localized_Messages');
	$expressiveness->package_resolver->provide(
		my $monad_class = '[=this_pkg=]::Monad');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub manual_individuality
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
#	?
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$meta_monad->provide(
		my $localized_messages = '::Individuality::Controlled::Localized_Messages');
	my $monad = $monad_class->indirect_constructor(
		$localized_messages);

	return($monad);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.68
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
