package Carrot::Continuity::Coordination::Episode::Target::Time_Boundary::Constants
# /type class
# /instances none
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	sub T_BOUNDARY_MINUTE()
	# /type constant  /inheritable
	{ 'M' }

	sub T_BOUNDARY_HOUR()
	# /type constant  /inheritable
	{ 'H' }

	sub T_BOUNDARY_DAY()
	# /type constant  /inheritable
	{ 'd' }

	sub T_BOUNDARY_MONTH()
	# /type constant  /inheritable
	{ 'm' }

	sub T_BOUNDARY_YEAR()
	# /type constant  /inheritable
	{ 'y' }

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.27
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
