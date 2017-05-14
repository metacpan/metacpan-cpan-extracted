package Carrot::Meta::Greenhouse::Static_Flags
# /type library
# /capability "Promotes the setting of simple compile-time flags."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Static_Flags./manual_modularity.pl');
	} #BEGIN

	require Carrot::Modularity::Constant::Global::Boolean;
	my $is_true = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
	my $is_false = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

# =--------------------------------------------------------------------------= #

sub SPX_VALUE() { 0 }
sub true_or_false($)
# /type function
# /effect "Returns a reference to the boolean constants true/false."
# //parameters
#	value
# //returns
#	::Personality::Abstract::Subroutine_Reference
{
	return(($_[SPX_VALUE] ? $is_true : $is_false));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.86
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
