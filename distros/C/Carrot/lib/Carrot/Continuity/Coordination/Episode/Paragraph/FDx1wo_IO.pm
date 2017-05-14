package Carrot::Continuity::Coordination::Episode::Paragraph::FDx1wo_IO
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;
	use POSIX qw(:errno_h);

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');
	$OS_SIGNALS{'PIPE'} = 'IGNORE'; # enables EPIPE globally to avoid sysaction() flooding

	$customized_settings->provide_plain_value(
		my $syswrite_size = 'syswrite_size');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	writer
#	fd
# //returns
#	?
{
	my ($this, $writer, $fd) = @ARGUMENTS;

	$this->[ATR_WRITER] = $writer;
	$this->[ATR_FD] = $fd;

	my $fd_nonstop_io = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, $fd);
	$fd_nonstop_io->activate;
	$fd_nonstop_io->fd_watch_write;
	$this->[ATR_TARGET] = $fd_nonstop_io;

	$this->[ATR_BUFFER] = '';
}

sub evt_fd_nonstop_validate_fh
# /type method
# /effect ""
# //parameters
# //returns
{}; # not implemented, yet

sub evt_fd_nonstop_exception
# /type method
# /effect ""
# //parameters
# //returns
{}; # no exchange of OOB-Data over Sockets

sub evt_fd_nonstop_read
# /type method
# /effect ""
# //parameters
# //returns
{}; # not requested

sub add_to_outbuffer
# /type method
# /effect ""
# //parameters
#	text  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->[ATR_BUFFER] .= $_ foreach @ARGUMENTS;

	if (length($this->[ATR_BUFFER]) > 0)
	{
		$this->[ATR_TARGET]->fd_watch_write;
		$this->[ATR_WRITER]->evt_fdx1wo_io_pending_output(1);
	}
	return;
}

sub flushed
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(length($_[THIS][ATR_BUFFER]) == 0);
}

sub evt_fd_nonstop_write
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if (length($this->[ATR_BUFFER]) == 0) { # $n == 0 indicates eof
		$this->[ATR_TARGET]->fd_ignore_write;
		$this->[ATR_WRITER]->evt_fdx1wo_io_pending_output(IS_FALSE);
		return;
	}

	WRITE: {
		my $n = syswrite(
			$this->[ATR_FD],
			$this->[ATR_BUFFER],
			$syswrite_size);
		unless (defined($n))
		{
#FIXME: log $OS_ERROR
			return() if ($this->is_temporary_error());
			$this->destructor;
			return;
		};
		if ($n == 0) { # eof
			$this->destructor;
			return;
		}
		substr($this->[ATR_BUFFER], 0, $n, '');
	}

	if (length($this->[ATR_BUFFER]) == 0)
	{
		$this->[ATR_TARGET]->fd_ignore_write;
		$this->[ATR_WRITER]->evt_fdx1wo_io_pending_output(IS_FALSE);
	}
	return;
}

sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TARGET]->deactivate;
#	POSIX::close() || warn("FD$fd: close: $OS_ERROR");
	$this->[ATR_WRITER]->evt_fdx1wo_ioattribute_destruction;
	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
#FIXME: why is this required?
	if (defined($_[THIS][ATR_TARGET]))
	{
		$_[THIS][ATR_TARGET]->deactivate;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.60
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"