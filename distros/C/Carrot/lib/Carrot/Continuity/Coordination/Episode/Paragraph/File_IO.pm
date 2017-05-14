package Carrot::Continuity::Coordination::Episode::Paragraph::File_IO
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	#FIXME: unfinished work
# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
__END__

use strict;
use warnings;
use bytes;
use POSIX qw(:errno_h);

	my $expressiveness = Carrot::individuality;
$expressiveness->provide(
	my $loop = '::Continuity::Coordination::Episode::Loop',
	my $customized_settings = '::Individuality::Controlled::Customized_Settings');
#sub PDX_SELECS_READ() { 0 };
#sub PDX_SELECS_WRITE() { 1 };
#sub PDX_SELECS_EXCEPTION() { 2 };

$SIG{'PIPE'} = 'IGNORE'; # enables EPIPE globally to avoid sysaction() flooding

$customized_settings->provide_plain_value(
	my $syswrite_size = 'syswrite_size');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	protocol
#	fd1
#	fd2
# //returns
#	?
{
	my ($this, $protocol, $fd1, $fd2) = @ARGUMENTS;

	$this->[ATR_PROTOCOL] = $protocol;

	my $fd_nonstop_io_in = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, \*STDIN);
	$fd_nonstop_io_in->activate;
	$fd_nonstop_io_in->fd_watch_read;
	$this->[ATR_IO_UNBLOCKED_IN] = $fd_nonstop_io_in;

	my $fd_nonstop_io_out = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, \*STDOUT);
	$fd_nonstop_io_out->activate;
	$this->[ATR_IO_UNBLOCKED_OUT] = $fd_nonstop_io_out;

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
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_IBUF_STATE] == BST_CLOSED);

	READ: {
		my $n = sysread(STDIN, my $buffer, $sysread_size);
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
#	texts  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	return if ($this->[ATR_OBUF_STATE] == BST_CLOSED); # no point
	$this->[ATR_OBUF] .= $_ foreach @ARGUMENTS;

	if (($this->[ATR_OBUF_STATE] == BST_IDLE)
	and (length($this->[ATR_OBUF]) > 0)) {
		$this->[ATR_IO_UNBLOCKED_OUT]->fd_watch_write;
		$this->[ATR_OBUF_STATE] = BST_BUSY;
		$this->[ATR_PROTOCOL]->evt_fdx2_io_pending_output(1);
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

		$this->[ATR_IO_UNBLOCKED_OUT]->fd_ignore_write;
		$this->[ATR_PROTOCOL]->evt_fdx2_io_pending_output(IS_FALSE);
		return;
	}

	WRITE: {
		my $n = syswrite(STDOUT, $this->[ATR_OBUF], $syswrite_size);
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
		$this->[ATR_IO_UNBLOCKED_OUT]->fd_ignore_write;
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
{ return(1) }; # FIXME


sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_IO_UNBLOCKED_IN]->deactivate;
	$this->[ATR_IO_UNBLOCKED_OUT]->deactivate;

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
	$_[THIS][ATR_IO_UNBLOCKED_IN]->fd_ignore_read;
	return;
}

sub set_bst_out_closed
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_OBUF_STATE] = BST_CLOSED;
	$_[THIS][ATR_IO_UNBLOCKED_OUT]->fd_ignore_write;
	return;
}

#sub is_bst_in { return($_[THIS][ATR_IBUF_STATE] == BST_CLOSED); };
#sub is_bst_out { return($_[THIS][ATR_OBUF_STATE] == BST_CLOSED); };


sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	foreach my $attribute (ATR_IO_UNBLOCKED_IN, ATR_IO_UNBLOCKED_OUT)
	{
		if (defined($_[THIS][$attribute]))
		{
			$_[THIS][$attribute]->deactivate;
		}
	}
}


return(1);
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"