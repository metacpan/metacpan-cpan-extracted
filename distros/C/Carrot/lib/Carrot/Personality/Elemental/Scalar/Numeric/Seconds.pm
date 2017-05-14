package Carrot::Personality::Elemental::Scalar::Numeric::Seconds
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Scalar/Numeric/Seconds./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub alarm
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::alarm(${$_[THIS]}));
}

sub localtime
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::localtime(${$_[THIS]}));
}

sub gmtime
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::gmtime(${$_[THIS]}));
}

#questionable
#sub timestamp_now
## method (<this>) public
#{
#	return(time);
#};

sub sleep
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::sleep(${$_[THIS]}));
}

sub sleep_milliseconds
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::select(undef, undef, undef, ${$_[THIS]}));
}

sub is_newer
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} > $_[SPX_VALUE]);
}

sub is_older
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} < $_[SPX_VALUE]);
}

sub is_same
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} == $_[SPX_VALUE]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.47
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
