package Carrot::Meta::Greenhouse::Compilation_Name
# /type class
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Compilation_Name./manual_modularity.pl');
	} #BEGIN

	my $carrot_arguments = Carrot::Meta::Greenhouse::Carrot_Arguments
		->constructor;
	$carrot_arguments->assign_if_exists('carrot-mode', my $name);
	if (exists($PROCESS_ENVIRONMENT{'CARROT_COMPILATION'}))
	{
		$name = $PROCESS_ENVIRONMENT{'CARROT_COMPILATION'};
	}
	$carrot_arguments->assign_if_exists('carrot-compilation', $name);

	my $this = bless(\$name, __PACKAGE__);

# =--------------------------------------------------------------------------= #

sub constructor
# /type function
# /effect "Returns an instance holding an undefined value"
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($this);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.14
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
