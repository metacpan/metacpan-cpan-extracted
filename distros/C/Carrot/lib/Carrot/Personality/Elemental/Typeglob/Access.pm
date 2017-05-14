package Carrot::Personality::Elemental::Typeglob::Access
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Typeglob/Access./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub access_position
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::tell(${$_[THIS]}, @ARGUMENTS));
}

sub access_position_directory
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::telldir(${$_[THIS]}, @ARGUMENTS));
}

sub advisory_lock
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(flock($$this, @ARGUMENTS));
}

sub close
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::close(${$_[THIS]}));
}

sub close_directory
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(close_directory(${$_[THIS]}));
}

sub end_of_file
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(eof(${$_[THIS]}));
}

sub fcntl
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(fcntl($$this, @ARGUMENTS));
}

sub ioctl
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::ioctl($$this, @ARGUMENTS));
}

sub numeric_file_descriptor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(fileno(${$_[THIS]}));
}

sub next_character
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(getc(${$_[THIS]}));
}

sub next_character
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(getc(${$_[THIS]}));
}

sub pipe
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::pipe($$this, @ARGUMENTS));
}

sub read
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::read($$this, @ARGUMENTS));
}

sub read_directory
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(readdir($$this, @ARGUMENTS));
}

sub readline
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
#	my $this = shift(\@ARGUMENTS);
	return(CORE::readline(${$_[THIS]}));
}

sub readpipe
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::readpipe(${$_[THIS]}));
}

sub rewinddir
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::rewinddir(${$_[THIS]}));
}

sub seek
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::seek(${$_[THIS]}, @ARGUMENTS));
}

sub select
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::select(${$_[THIS]}, @ARGUMENTS));
}

sub sys_open
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::sysopen(${$_[THIS]}, @ARGUMENTS));
}

sub sys_read
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::sysread(${$_[THIS]}, @ARGUMENTS));
}

sub sys_seek
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::sysseek(${$_[THIS]}, @ARGUMENTS));
}

sub sys_write
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(CORE::sysseek(${$_[THIS]}, @ARGUMENTS));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.74
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
