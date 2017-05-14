package Carrot::Meta::Greenhouse::Minimal_Constructor
# /type library
# /capability "A library of minimal constructors."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Minimal_Constructor./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub scalar_based
# /type function
# /effect "Returns an instance holding an undefined value"
# //parameters
#	class_name
# //returns
#	::Personality::Abstract::Instance
{
	my $scalar = undef;
	return(bless(\$scalar, $_[SPX_CLASS]));
}

sub array_based
# /type function
# /effect "Returns an instance holding an empty array"
# //parameters
#	class_name
# //returns
#	::Personality::Abstract::Instance
{
	return(bless([], $_[SPX_CLASS]));
}

sub hash_based
# /type function
# /effect "Returns an instance holding an empty hash"
# //parameters
#	class_name
# //returns
#	::Personality::Abstract::Instance
{
	return(bless({}, $_[SPX_CLASS]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.24
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
