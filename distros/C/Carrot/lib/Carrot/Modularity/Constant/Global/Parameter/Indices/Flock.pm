package Carrot::Modularity::Constant::Global::Parameter::Indices::Flock
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Indices/Flock./manual_modularity.pl');
	} #BEGIN

	sub PDX_FLOCK_SHARED() { 1 };
	sub PDX_FLOCK_EXCLUSIVE() { 2 };
	sub PDX_FLOCK_NONBLOCKING() { 4 };
	sub PDX_FLOCK_UNLOCK() { 8 };

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('PDX_FLOCK_', [qw(
		SHARED
		EXCLUSIVE
		NONBLOCKING
		UNLOCK)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.42
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
