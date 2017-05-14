package Carrot::Modularity::Constant::Global::Operating_System::Unix
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Operating_System/Unix./manual_modularity.pl');
	} #BEGIN

	sub UNIX_FS_PATH_DELIMITER()    { '/' }
	sub UNIX_FS_IGNORES_CASE()      { 0 }
	sub UNIX_FS_PARENT_DIRECTORY()  { '..' }
	sub UNIX_FS_CURRENT_DIRECTORY() { '.' }
	sub UNIX_FS_ROOT_DIRECTORY()    { '/' }
	sub UNIX_FS_NULL_DEVICE()       { '/dev/null' }

	sub UNIX_NEEDS_BINMODE()        { 0 }

	sub UNIX_TEXT_NEWLINE()         { "\012" }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array
{
	return('UNIX_', [qw(
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
#	version 1.1.34
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
