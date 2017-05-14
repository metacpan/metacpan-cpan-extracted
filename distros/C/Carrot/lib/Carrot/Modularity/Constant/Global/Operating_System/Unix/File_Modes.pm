package Carrot::Modularity::Constant::Global::Operating_System::Unix::File_Modes
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Operating_System/Unix/File_Modes./manual_modularity.pl');
	} #BEGIN

	sub UNX_FILE_MODE__ZERO()             { 0 }

	sub UNX_FILE_MODE__OTHERS()            { 0b000000111 }
	sub UNX_FILE_MODE__OTHERS_EXECUTABLE() { 0b000000001 }
	sub UNX_FILE_MODE__OTHERS_WRITABLE()   { 0b000000010 }
	sub UNX_FILE_MODE__OTHERS_READABLE()   { 0b000000100 }

	sub UNX_FILE_MODE__GROUP()            { 0b000111000 }
	sub UNX_FILE_MODE__GROUP_EXECUTABLE() { 0b000001000 }
	sub UNX_FILE_MODE__GROUP_WRITABLE()   { 0b000010000 }
	sub UNX_FILE_MODE__GROUP_READABLE()   { 0b000100000 }

	sub UNX_FILE_MODE__USER()             { 0b111000000 }
	sub UNX_FILE_MODE__USER_EXECUTABLE()  { 0b001000000 }
	sub UNX_FILE_MODE__USER_WRITABLE()    { 0b010000000 }
	sub UNX_FILE_MODE__USER_READABLE()    { 0b100000000 }

	sub UNX_FILE_MODE__ANY()              { 0b111111111 }
	sub UNX_FILE_MODE__ANY_EXECUTABLE()   { 0b001001001 }
	sub UNX_FILE_MODE__ANY_WRITABLE()     { 0b010010010 }
	sub UNX_FILE_MODE__ANY_READABLE()     { 0b100100100 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array
{
	return('UNX_FILE_MODE', [qw(
		ZERO

		OTHERS
		OTHERS_EXECUTABLE
		OTHERS_WRITABLE
		OTHERS_READABLE

		GROUP
		GROUP_EXECUTABLE
		GROUP_WRITABLE
		GROUP_READABLE

		USER
		USER_EXECUTABLE
		USER_WRITABLE
		USER_READABLE

		ANY
		ANY_EXECUTABLE
		ANY_WRITABLE
		ANY_READABLE)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
