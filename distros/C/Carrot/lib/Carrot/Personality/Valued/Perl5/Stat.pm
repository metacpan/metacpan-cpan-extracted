package Carrot::Personality::Valued::Perl5::Stat
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Perl5/Stat./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub storage_device
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_STORAGE_DEVICE]);
}

sub inode
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_INODE]);
}

sub mode
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_MODE]);
}

sub hard_link_count
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_LINKS]);
}

sub uid
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_UID]);
}

sub gid
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_GID]);
}

sub device
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_DEVICE]);
}

sub byte_size
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_SIZE]);
}

sub access_time
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_ATIME]);
}

sub modification_time
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_MTIME]);
}

sub status_change_time
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_CTIME]);
}

sub io_block_size
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_BLKSIZE]);
}

sub block_count
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_STAT_BLOCKS]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.50
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
