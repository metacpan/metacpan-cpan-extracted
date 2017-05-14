package Carrot::Meta::Greenhouse::Fatal_Syscalls
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Fatal_Syscalls./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub open
# /type method
# /effect ""
# //parameters
#	handle
#	mode
#	name
# //returns
{
	return(CORE::open($_[SPX_1ST_ARGUMENT],
		$_[SPX_2ND_ARGUMENT],
		$_[SPX_3RD_ARGUMENT])
		// die("open/$_[SPX_2ND_ARGUMENT]: $OS_ERROR"));
}

sub read
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::read($_[SPX_1ST_ARGUMENT],
		$_[SPX_2ND_ARGUMENT],
		$_[SPX_3RD_ARGUMENT]) //
		die("read: $OS_ERROR"));
}

sub truncate
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::truncate($_[SPX_1ST_ARGUMENT],
		$_[SPX_2ND_ARGUMENT]) //
		die("truncate: $OS_ERROR"));
}

sub seek
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::seek($_[SPX_1ST_ARGUMENT],
		$_[SPX_2ND_ARGUMENT],
		$_[SPX_3RD_ARGUMENT]) ||
		die("seek: $OS_ERROR"));
}

sub close
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::close($_[SPX_1ST_ARGUMENT]) ||
		die("close: $OS_ERROR"));
}

sub stat
# /type method
# /effect ""
# //parameters
#	handle
# //returns
{
	my $rv = [CORE::stat($_[SPX_1ST_ARGUMENT])];
	unless (@$rv)
	{
		die("stat: $OS_ERROR");
	}
	return($rv);
}

sub lstat
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	my $rv = [CORE::lstat($_[SPX_1ST_ARGUMENT])];
	unless (@$rv)
	{
		die("lstat: $OS_ERROR");
	}
	return($rv);
}

sub print
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return((CORE::print {$_[SPX_1ST_ARGUMENT]} $_[SPX_2ND_ARGUMENT]) ||
		die("print: $OS_ERROR"));
}

sub print2
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return((CORE::print {$_[SPX_1ST_ARGUMENT]}
		$_[SPX_2ND_ARGUMENT],
		$_[SPX_3RD_ARGUMENT]) ||
		die("print: $OS_ERROR"));
}

sub opendir
# /type method
# /effect ""
# //parameters
#	handle
#	name
# //returns
#	?
{
	return(CORE::opendir($_[SPX_1ST_ARGUMENT], $_[SPX_2ND_ARGUMENT]) ||
		die("opendir: $OS_ERROR"));
}

sub readdir
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return([CORE::readdir($_[SPX_1ST_ARGUMENT])] ||
		die("readdir: $OS_ERROR"));
}

sub closedir
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::closedir($_[SPX_1ST_ARGUMENT]) ||
		die("closedir: $OS_ERROR"));
}

sub mkdir
# /type method
# /effect ""
# //parameters
#	handle
# //returns
#	?
{
	return(CORE::mkdir($_[SPX_1ST_ARGUMENT]) ||
		die("mkdir: $OS_ERROR"));
}

sub fork
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::fork //
		die("fork: $OS_ERROR"));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.49
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
