package Carrot::Continuity::Operation::Program::_Plugin_Prototype
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Defines the prototype (interface) of a program plugin."
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub activate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
# //returns
# /prototype mandatory
;

sub deactivate
# /type method
# /effect "De-activates the main feature of the instance."
# //parameters
# //returns
# /prototype mandatory
;

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.131
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
