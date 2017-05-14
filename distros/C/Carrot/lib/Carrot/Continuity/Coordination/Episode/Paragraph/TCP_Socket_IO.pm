package Carrot::Continuity::Coordination::Episode::Paragraph::TCP_Socket_IO
# /type class
# /attribute_type ::Many_Declared::Ordered
# //tabulators
#	::Buffer
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;
	use POSIX qw(:errno_h);
	use IO::SendFile;

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $class_names = '::Individuality::Controlled::Class_Names',
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$customized_settings->provide_plain_value(
		my $sysread_size = 'sysread_size',
		my $syswrite_size = 'syswrite_size',
		my $maximum_error_retries = 'maximum_error_retries');

	$class_names->provide(
		'[=project_pkg=]::Paragraph::TCP_Socket_IO::Buffer::',
			my $input_buffer_class = '::Input',
			my $output_buffer_class = '::Output');

# =--------------------------------------------------------------------------= #

sub INOUT_STOP() { -1 }
sub INOUT_NOCHANGE() { 0 }
sub INOUT_START() { 1 }

sub BUF_CONTENT() { 0 };
sub BUF_OFFSET() { 1 };
sub BUF_LEFT() { 2 };
sub BUF_IS_FILE() { 3 };

$OS_SIGNALS{'PIPE'} = 'IGNORE'; # enables EPIPE globally to avoid sysaction() flooding

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	socket
#	io_timeout
#	protocol
# //returns
{
	my ($this, $socket, $io_timeout, $protocol) = @ARGUMENTS;

	$this->[ATR_SOCKET] = $socket;

	my $fd_nonstop_io = $loop->construct_standard_episode(
		'::Target::FD_Nonstop_IO', $this, $socket);
	$fd_nonstop_io->activate;
	$fd_nonstop_io->fd_watch_read;
	$this->[ATR_TARGET] = $fd_nonstop_io;

	$this->[ATR_INPUT] = $input_buffer_class->indirect_constructor($protocol);
	$this->[ATR_OUTPUT] = $output_buffer_class->indirect_constructor;

	$this->[ATR_TIMEOUT] = $loop->construct_standard_episode(
		'::Target::Timeout', $this, $io_timeout);
	$this->[ATR_TIMEOUT]->activate;

	return;
}

sub poll_input_buffer
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return(IS_UNDEFINED) if ($this->[ATR_OUTPUT]->is_closed);
	$this->pause_input($this->[ATR_INPUT]->process_data(IS_FALSE));
	return($this->[ATR_INPUT]->has_data);
}

sub close_buffers
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TARGET]->fd_ignore_read;
	$this->[ATR_TARGET]->fd_ignore_write;
	$this->[ATR_INPUT]->close;
	$this->[ATR_OUTPUT]->close;
	return;
}

sub evt_time_timeout
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless (defined($this->[ATR_SOCKET]));
	$this->close_buffers;
	$this->[ATR_TIMEOUT]->deactivate;
	$this->[ATR_TARGET]->deactivate;
	my $fd = fileno($this->[ATR_SOCKET]);
	POSIX::close($fd) || warn("FD$fd: close: $OS_ERROR");
	$this->[ATR_SOCKET] = IS_UNDEFINED;

	return;
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

	my $buffer_ref = $this->[ATR_INPUT]->read_buffer;
	return unless (defined($buffer_ref));
	$this->[ATR_TIMEOUT]->refresh;

	my $n;
	my $retries = 0;
	while (IS_TRUE)
	{
		if ($retries > $maximum_error_retries)
		{
			$this->close_buffers;
			return;
		};
		$retries += 1;
		$n = sysread($this->[ATR_SOCKET],
			$$buffer_ref,
			$sysread_size);
		last if (defined($n));
#FIXME: log $OS_ERROR
# mostly ($OS_ERROR == EPIPE)
		next if ($this->is_temporary_error($OS_ERROR));
		$this->close_buffers;
		return;
	}
	if ($n == 0) { # eof for non-blocking case
		$this->close_buffers;
		return;
	}
	$this->pause_input($this->[ATR_INPUT]->process_data($n));
	return;
}

sub evt_fd_nonstop_write
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $buffer = $this->[ATR_OUTPUT]->data;
	$this->[ATR_TIMEOUT]->refresh;

	my $n;
	my $retries = 0;
	while (IS_TRUE)
	{
		if ($retries > $maximum_error_retries)
		{
			$this->close_buffers;
			return;
		};
		if ($buffer->[BUF_IS_FILE])
		{
			$n = IO::SendFile::sendfile(
				fileno($this->[ATR_SOCKET]),
				fileno($buffer->[BUF_CONTENT]),
				$buffer->[BUF_OFFSET],
				$buffer->[BUF_LEFT]);
		} else {
			$n = syswrite(
				$this->[ATR_SOCKET],
				${$buffer->[BUF_CONTENT]},
				$syswrite_size,
				$buffer->[BUF_OFFSET]);
		}

		last if (defined($n));
#FIXME: log $OS_ERROR
		next if ($this->is_temporary_error($OS_ERROR));
		$this->close_buffers;
		return;
	}

	if ($n == 0) { # eof
		$this->close_buffers;
		return;
	}
	$this->pause_output($this->[ATR_OUTPUT]->written($n));
	return;
}

sub scalar_output
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	$_[THIS]->pause_output($_[THIS][ATR_OUTPUT]->add_scalar($_[SPX_BUFFER]));
	return;
}

sub file_handle_output
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	$_[THIS]->pause_output($_[THIS][ATR_OUTPUT]->add_file_handle($_[SPX_BUFFER]));
	return;
}

sub is_temporary_error
# /type method
# /effect ""
# //parameters
#	error_number
# //returns
#	::Personality::Abstract::Boolean
{
	return(IS_TRUE) if (($_[SPX_ERROR_NUMBER] == EAGAIN)
		or ($_[SPX_ERROR_NUMBER] == EINTR)
		or ($_[SPX_ERROR_NUMBER] == EINPROGRESS)
		or ($_[SPX_ERROR_NUMBER] == ENOMEM));
	return(IS_FALSE);
}

sub set_timeout
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	if ($_[SPX_VALUE] == 0)
	{
		$_[THIS][ATR_TIMEOUT]->deactivate;
	} else {
		$_[THIS][ATR_TIMEOUT]->adjust($_[SPX_VALUE]);
	}
	return;
}

sub pause_input
# /type method
# /effect ""
# //parameters
#	test_result
# //returns
{
	my ($this, $test_result) = @ARGUMENTS;

	if ($test_result == INOUT_START)
	{
		$this->[ATR_TARGET]->fd_watch_read;
	} elsif ($test_result == INOUT_STOP)
	{
		$this->[ATR_TARGET]->fd_ignore_read;
	}

	return;
}

sub pause_output
# /type method
# /effect ""
# //parameters
#	test_result
# //returns
{
	my ($this, $test_result) = @ARGUMENTS;

	if ($test_result == INOUT_START)
	{
		$this->[ATR_TARGET]->fd_watch_write;
	} elsif ($test_result == INOUT_STOP)
	{
		if ($this->[ATR_INPUT]->is_closed)
		{
			$this->[ATR_OUTPUT]->close;
		}
		$this->[ATR_TARGET]->fd_ignore_write;
	}

	return;
}

sub is_alive
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(IS_FALSE) unless (defined($this->[ATR_SOCKET]));
	return($this->[ATR_SOCKET]->connected
		and not $this->[ATR_OUTPUT]->is_closed);
}

sub shutdown_input_buffer
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_TARGET]->fd_ignore_read;
	$_[THIS][ATR_INPUT]->close;
	return;
}

sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
# //returns
{
	if (defined($_[THIS][ATR_SOCKET]))
	{
		$_[THIS]->evt_time_timeout;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.70
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"