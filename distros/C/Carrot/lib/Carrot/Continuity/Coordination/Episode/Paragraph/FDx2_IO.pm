package Carrot::Continuity::Coordination::Episode::Paragraph::FDx2_IO
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

# =--------------------------------------------------------------------------= #

sub BST_CLOSED() { 0 };
sub BST_BUSY() { 1 };
sub BST_IDLE() { 2 };

$OS_SIGNALS{'PIPE'} = 'IGNORE'; # enables EPIPE globally to avoid sysaction() flooding

#WARNING: This module is not symmetric!
# Reading is not the opposite, reverse or mirror of writing.

$customized_settings->provide_plain_value(
	my $sysread_size = 'sysread_size',
	my $syswrite_size = 'syswrite_size');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	protocol
#	fd_in
#	fd_out
# //returns
#	?
{
	my ($this, $protocol, $fd_in, $fd_out) = @ARGUMENTS;

	$this->[ATR_PROTOCOL] = $protocol;
	$this->[ATR_FD_IN] = $fd_in;
	$this->[ATR_FD_OUT] = $fd_out;

	my $fd_nonstop_io_in = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, $fd_in);
	$fd_nonstop_io_in->activate;
	$fd_nonstop_io_in->fd_watch_read;
	$this->[ATR_TARGET_IN] = $fd_nonstop_io_in;

	$this->[ATR_TARGET_OUT] = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, $fd_out);
	$this->[ATR_TARGET_OUT]->activate;

	$this->[ATR_IBUF] = '';
	$this->[ATR_OBUF] = '';
	$this->[ATR_IBUF_STATE] = BST_IDLE;
	$this->[ATR_OBUF_STATE] = BST_IDLE;
}


sub evt_fd_nonstop_validate_fh
# /type method
# /effect ""
# //parameters
# //returns
{
} # not implemented, yet

sub evt_fd_nonstop_exception
# /type method
# /effect ""
# //parameters
# //returns
{
} # no exchange of OOB-Data over Sockets

sub evt_fd_nonstop_read
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_IBUF_STATE] == BST_CLOSED);

	READ: {
		my $n = sysread($this->[ATR_FD_IN], my $buffer, $sysread_size);
		unless (defined($n)) { # mostly ($OS_ERROR == EPIPE)
#FIXME: log $OS_ERROR
			redo READ if ($this->is_temporary_error());
			$this->destructor;
			return;
		};
		if ($n == 0) { # eof for non-blocking case
			$this->destructor;
			return;
		}
		$this->[ATR_IBUF] .= $buffer;
	}

	if (length($this->[ATR_IBUF]) > 0)
	{
		$this->[ATR_PROTOCOL]->evt_fdx2_io_received_input($this->[ATR_IBUF]);
	}
	return;
}


sub add_to_outbuffer
# /type method
# /effect ""
# //parameters
#	text  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	return if ($this->[ATR_OBUF_STATE] == BST_CLOSED); # no point
	$this->[ATR_OBUF] .= $_ foreach @ARGUMENTS;

	if (($this->[ATR_OBUF_STATE] == BST_IDLE)
	and (length($this->[ATR_OBUF]) > 0)) {
		$this->[ATR_TARGET_OUT]->fd_watch_write;
		$this->[ATR_OBUF_STATE] = BST_BUSY;
		$this->[ATR_PROTOCOL]->evt_fdx2_io_pending_output(IS_TRUE);
	}
	return;
}


sub evt_fd_nonstop_write
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_OBUF_STATE] == BST_CLOSED); # no point
	if (length($this->[ATR_OBUF]) == 0) { # $n == 0 indicates eof

		$this->[ATR_TARGET_OUT]->fd_ignore_write;
		$this->[ATR_PROTOCOL]->evt_fdx2_io_pending_output(IS_FALSE);
		return;
	}

	WRITE: {
		my $n = syswrite(
			$this->[ATR_FD_OUT],
			$this->[ATR_OBUF],
			$syswrite_size);
		unless (defined($n))
		{
#FIXME: log $OS_ERROR
			return if ($this->is_temporary_error());
			$this->destructor;
			return;
		};
		if ($n == 0) { # eof
			$this->destructor;
			return;
		}
		substr($this->[ATR_OBUF], 0, $n, '');
	}

	if (length($this->[ATR_OBUF]) == 0)
	{
		$this->[ATR_TARGET_OUT]->fd_ignore_write;
		$this->[ATR_OBUF_STATE] = BST_IDLE;
		$this->[ATR_PROTOCOL]->evt_fdx2_io_pending_output(IS_FALSE);
	}
	return;
}



sub is_temporary_error
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	if (($OS_ERROR == EAGAIN)
	or ($OS_ERROR == EINTR)
	or ($OS_ERROR == EINPROGRESS)
	or ($OS_ERROR == ENOMEM)) {
		return(IS_TRUE);
	}
	return(IS_FALSE);
}


sub is_alive
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(IS_TRUE);
} # FIXME


sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TARGET_IN]->deactivate;
	$this->[ATR_TARGET_OUT]->deactivate;

#	my $fd = fileno($this->[ATR_SOCKET]);
#	POSIX::close($fd) || warn("FD$fd: close: $OS_ERROR");

	$this->[ATR_PROTOCOL]->evt_fdx2_io_drop;
	return;
}


sub set_bst_in_closed
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_IBUF_STATE] = BST_CLOSED;
	$_[THIS][ATR_TARGET_IN]->fd_ignore_read;
	return;
}

sub set_bst_out_closed
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_OBUF_STATE] = BST_CLOSED;
	$_[THIS][ATR_TARGET_OUT]->fd_ignore_write;
	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	foreach my $attribute (ATR_TARGET_IN, ATR_TARGET_OUT)
	{
		if (defined($_[THIS][$attribute]))
		{
			$_[THIS][$attribute]->deactivate;
		}
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.67
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"