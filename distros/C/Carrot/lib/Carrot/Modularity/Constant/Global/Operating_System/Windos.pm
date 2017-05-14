package Carrot::Modularity::Constant::Global::Operating_System::Windos
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Operating_System/Windos./manual_modularity.pl');
	} #BEGIN

	sub WINDOS_FS_PATH_DELIMITER()    { '\\' }
	sub WINDOS_FS_IGNORES_CASE()      { 1 }
	sub WINDOS_FS_PARENT_DIRECTORY()  { '..' }
	sub WINDOS_FS_CURRENT_DIRECTORY() { '.' }
	sub WINDOS_FS_ROOT_DIRECTORY()    { '\\' }
	sub WINDOS_FS_NULL_DEVICE()       { 'nul:' }

	sub WINDOS_NEEDS_BINMODE()        { 1 }

	sub WINDOS_TEXT_NEWLINE()         { "\012" }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array
{
	return('WINDOS_', [qw(
		FS_PATH_DELIMITER
		FS_IGNORES_CASE
		FS_PARENT_DIRECTORY
		FS_CURRENT_DIRECTORY
		FS_ROOT_DIRECTORY
		FS_NULL_DEVICE
		NEEDS_BINMODE
		TEXT_NEWLINE)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.20
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
