package Carrot::Modularity::Constant::Global::Operating_System
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Operating_System./manual_modularity.pl');
	} #BEGIN

	my $current_os;
	if (grep(($OS_NAME eq $_), qw(aix freebsd linux hpux irix openbsd dec_osf svr4 unicos solaris sunos)))
	{
		require Carrot::Modularity::Constant::Global::Operating_System::Unix;
		$current_os = 'Carrot::Modularity::Constant::Global::Operating_System::Unix::UNIX';
		eval "sub OS_TYPE() { 'Unix' }";

	} elsif ($OS_NAME eq 'MSWin32')
	{
		require Carrot::Modularity::Constant::Global::Operating_System::Windos;
		$current_os = 'Carrot::Modularity::Constant::Global::Operating_System::Windos::WINDOS';
		eval "sub OS_TYPE() { 'Windos' }";

	}

	*OS_FS_PATH_DELIMITER = \&{$current_os.'_FS_PATH_DELIMITER'};
	*OS_FS_IGNORES_CASE = \&{$current_os.'_FS_IGNORES_CASE'};
	*OS_FS_PARENT_DIRECTORY = \&{$current_os.'_FS_PARENT_DIRECTORY'};
	*OS_FS_CURRENT_DIRECTORY = \&{$current_os.'_FS_CURRENT_DIRECTORY'};
	*OS_FS_ROOT_DIRECTORY = \&{$current_os.'_FS_ROOT_DIRECTORY'};
	*OS_FS_NULL_DEVICE = \&{$current_os.'_FS_NULL_DEVICE'};

	*OS_NEEDS_BINMODE = \&{$current_os.'_NEEDS_BINMODE'};

	*OS_TEXT_NEWLINE = \&{$current_os.'_TEXT_NEWLINE'};

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array
{
	return('OS_', [qw(
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
#	version 1.1.37
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
