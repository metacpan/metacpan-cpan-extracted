package Carrot::Individuality::Controlled::Distinguished_Exceptions::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $potential_class = '[=project_pkg=]::Potential');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	resolver
# //returns
{
	my ($this, $resolver) = @ARGUMENTS;

	$this->[ATR_RESOLVER] = $resolver;

	return;
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		my $exception = $potential_class->indirect_constructor(
			$this->[ATR_RESOLVER],
			$name);
		$name = $exception;
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"