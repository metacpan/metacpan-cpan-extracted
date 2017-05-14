package Carrot::Continuity::Operation::Program::Data_Potential::Process
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;
	#use Carrot::Continuity::Coordination::Episode::Loop;

# =--------------------------------------------------------------------------= #

sub get_potential
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return([
		['pid', \&syp_pid]
		]);
}

sub syp_pid($$)
# function ()
{
	return($PROCESS_PID);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
