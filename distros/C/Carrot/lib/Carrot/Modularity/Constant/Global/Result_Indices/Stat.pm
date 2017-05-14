package Carrot::Modularity::Constant::Global::Result_Indices::Stat
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Stat./manual_modularity.pl');
	} #BEGIN

	sub RDX_STAT_STORAGE_DEVICE() { 0 }
	sub RDX_STAT_INODE() { 1 }
	sub RDX_STAT_MODE() { 2 }
	sub RDX_STAT_LINKS() { 3 }
	sub RDX_STAT_UID() { 4 }
	sub RDX_STAT_GID() { 5 }
	sub RDX_STAT_DEVICE() { 6 }
	sub RDX_STAT_SIZE() { 7 }
	sub RDX_STAT_ATIME() { 8 }
	sub RDX_STAT_MTIME() { 9 }
	sub RDX_STAT_CTIME() { 10 }
	sub RDX_STAT_BLKSIZE() { 11 }
	sub RDX_STAT_BLOCKS() { 12 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_STAT_', [qw(
		STORAGE_DEVICE
		INODE
		MODE
		LINKS
		UID
		GID
		DEVICE
		SIZE
		ATIME
		MTIME
		CTIME
		BLKSIZE
		BLOCKS)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.38
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
