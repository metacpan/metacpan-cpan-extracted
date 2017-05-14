package Carrot::Continuity::Coordination::Episode::Source::FD_Nonstop_IO
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;
	use POSIX qw(floor);

	my $expressiveness = Carrot::individuality;
	$expressiveness->distinguished_exceptions->provide(
		my $outbound_file_descriptor = 'outbound_file_descriptor');

	$expressiveness->class_names->provide_instance(
		my $loop = '[=project_pkg=]::Loop');

	my $fd_max = eval { POSIX::sysconf(&POSIX::_SC_OPEN_MAX) - 1 } || 1023;
	my $null_byte = pack('x', 0);

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_WANTS] = ['', '', ''];
	$this->[ATR_GOT] = ['', '', ''];
	$this->[ATR_DETECTED] = 0;
	$this->[ATR_TARGETS] = [];
	$this->[ATR_ZEROS] = '';

	$loop->register($this);
	return;
}

sub priority_high
# /type method
# /effect ""
# //parameters
# //returns
{
	return;
}

sub await
# /type method
# /effect ""
# //parameters
#	timeout         ::Personality::Abstract::Seconds
# //returns
#	?
{
	my ($this, $timeout) = @ARGUMENTS;

	$this->[ATR_DETECTED] = 0;
	my $got = $this->[ATR_GOT];
	my $wants = $this->[ATR_WANTS];
	$got->[PDX_SELECS_READ] = $wants->[PDX_SELECS_READ];
	$got->[PDX_SELECS_WRITE] = $wants->[PDX_SELECS_WRITE];
	$got->[PDX_SELECS_EXCEPTION] = $wants->[PDX_SELECS_EXCEPTION];

	my $waiting = 1;
	while ($waiting < 10)
	{
#	    print STDERR "---------------------------------------\n";
#	$this->dump_vectors(ATR_WANTS, PDX_SELECS_READ, PDX_SELECS_WRITE);
		my $found = select(
			$got->[PDX_SELECS_READ],
			$got->[PDX_SELECS_WRITE],
			$got->[PDX_SELECS_EXCEPTION], $timeout);
#	$this->dump_vectors(ATR_GOT, PDX_SELECS_READ, PDX_SELECS_WRITE);
		if ($found == -1)
		{
			$waiting += 1;
			next unless ($this->sys_E# /type method
# /effect ""
# //parameters
# //returns
#	?());
			last;
		}
		$this->[ATR_DETECTED] = $found;
		last;
	}
	return($this->[ATR_DETECTED]);
}

sub sys_EXXX
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if ($OS_ERROR == POSIX::EBADF)
	{
		# An invalid file descriptor was given in one of the sets.
#D#			$this->fd_info();
#D#			$this->dump(ATR_WANTS, PDX_SELECS_READ, PDX_SELECS_WRITE);
#D#			$this->dump(ATR_GOT, PDX_SELECS_READ, PDX_SELECS_WRITE);
		$this->validate_target_fhs();
	} elsif (($OS_ERROR == POSIX::EAGAIN) or ($OS_ERROR == POSIX::EINTR) or
		($OS_ERROR == POSIX::EINPROGRESS) or ($OS_ERROR == POSIX::ENOMEM))
	{
		return(PERL_FILE_LOADED);
	} elsif ($OS_ERROR == POSIX::EINVAL)
	{
		# n is negative or the value contained within timeout is invalid.
	} else {
#D#			print STDERR "got errno=", int($OS_ERROR), "#\n"; # what a lousy language
	}
	return(IS_FALSE);
}

sub dispatch
# /type method
# /effect ""
# //parameters
#	target
#	fd
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless ($this->[ATR_DETECTED]);

	my $got = $this->[ATR_GOT];
	my @r_bytes = map(unpack("C", $_),
		split('', $got->[PDX_SELECS_READ], PKY_SPLIT_RETURN_FULL_TRAIL));
	my @w_bytes = map(unpack("C", $_),
		split('', $got->[PDX_SELECS_WRITE], PKY_SPLIT_RETURN_FULL_TRAIL));
	my @e_bytes = map(unpack("C", $_),
		split('', $got->[PDX_SELECS_EXCEPTION], PKY_SPLIT_RETURN_FULL_TRAIL));
	my $left = $this->[ATR_DETECTED];

	my $targets = $this->[ATR_TARGETS];
	my $i = ADX_NO_ELEMENTS;
BYTE: while ($#r_bytes > ADX_NO_ELEMENTS) {
		my @got = (shift(@r_bytes), shift(@w_bytes), shift(@e_bytes));
		my $got_any = $got[PDX_SELECS_READ]
			+ $got[PDX_SELECS_WRITE]
			+ $got[PDX_SELECS_EXCEPTION];
		if ($got_any == 0)
		{
			$i += 8;
			next;
		}
		foreach my $mask (1, 2, 4, 8, 16, 32, 64, 128)
		{
			$i += 1;
			my @flags = (($got[PDX_SELECS_READ] & $mask),
				($got[PDX_SELECS_WRITE] & $mask),
				($got[PDX_SELECS_EXCEPTION] & $mask));
			my $flagged = $flags[PDX_SELECS_READ]
				+ $flags[PDX_SELECS_WRITE]
				+ $flags[PDX_SELECS_EXCEPTION];
			if ($flagged > 0)
			{
				my $target = $targets->[$i];
				$target->hit(PDX_SELECS_EXCEPTION, $i)
					if ($flags[PDX_SELECS_EXCEPTION]);
				$target->hit(PDX_SELECS_READ, $i)
					if ($flags[PDX_SELECS_READ]);
				$target->hit(PDX_SELECS_WRITE, $i)
					if ($flags[PDX_SELECS_WRITE]);
				$left -= $flagged;
			}
			last BYTE if ($left == 0);
		}
	}
	return;
}

sub register
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
#	::Personality::Abstract::Boolean
{ # allocates space
	my ($this, $target, $fd) = @ARGUMENTS;

	if (ASSERTION_FLAG)
	{
		if (($fd < 0) or ($fd > $fd_max))
		{
			$outbound_file_descriptor->raise_exception(
				{+HKY_DEX_BACKTRACK => $fd,
				 'file_descriptor' => scalar($fd) },
				ERROR_CATEGORY_SETUP);
		}
	}

	my $l = length($this->[ATR_ZEROS]);
	my $enlarge = (int($fd/8) -$l +1);
	if ($enlarge > 0)
	{
		my $extension = $null_byte x $enlarge;
		$this->[ATR_ZEROS] .= $extension;
		map($_ .= $extension,
			@{$this->[ATR_WANTS]}, @{$this->[ATR_GOT]});
	}

#	$caller_backtrace->trigger_fatal unless (DEBUG_FLAG and defined($caller));
#	print STDERR "$$ register $caller fd=$fd\n";
	$this->[ATR_TARGETS][$fd] = $target;
	return(PERL_FILE_LOADED);
}

sub deregister
# /type method
# /effect ""
# //parameters
#	rwe
#	fd
# //returns
#	::Personality::Abstract::Boolean
{ # releases space
	my ($this, $target, $fd) = @ARGUMENTS;

	map(vec($_, $fd, 1) = 0,
		@{$_[THIS][ATR_WANTS]}, @{$_[THIS][ATR_GOT]});

	my $targets = $this->[ATR_TARGETS];
	$targets->[$fd] = IS_UNDEFINED;
	# remove_undefined_at_end
	while (($#$targets > ADX_NO_ELEMENTS) and not defined($targets->[ADX_LAST_ELEMENT]))
	{
		pop($targets);
	}

	my $downsize = (POSIX::floor($#{$this->[ATR_TARGETS]} /8) +1
		-length($this->[ATR_ZEROS]));
	if ($downsize)
	{
		substr($this->[ATR_ZEROS], -$downsize) = '';
		map(substr($_, -$downsize) = '',
			@{$this->[ATR_WANTS]}, @{$this->[ATR_GOT]});
	}

	return(PERL_FILE_LOADED);
}

sub fd_zero
# /type method
# /effect ""
# //parameters
#	rwe
#	fd
# //returns
{
	$_[THIS][ATR_WANTS][$_[SPX_RWE]] =
		$_[THIS][ATR_WANTS][$_[SPX_RWE]] ^ $_[THIS][ATR_WANTS][$_[SPX_RWE]];
	return;
}

sub fd_ignore
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
{
	vec($_[THIS][ATR_WANTS][$_[SPX_RWE]], $_[SPX_FD], 1) = 0;
	return;
}

sub fd_watch
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
{
	vec($_[THIS][ATR_WANTS][$_[SPX_RWE]], $_[SPX_FD], 1) = 1;
	return;
}

sub fd_ignore_all
# /type method
# /effect ""
# //parameters
#	rwe
#	fd
# //returns
{
	map(vec($_, $_[SPX_RWE], 1) = 0,
		@{$_[THIS][ATR_WANTS]});
	return;
}

sub fd_watch_all
# /type method
# /effect ""
# //parameters
# //returns
{
	map(vec($_, $_[SPX_RWE], 1) = 1,
		@{$_[THIS][ATR_WANTS]});
	return;
}

sub fd_watches
# /type method
# /effect ""
# //parameters
#	fds
# //returns
#	::Personality::Abstract::Boolean
{
	(vec($_[THIS][ATR_GOT][$_[SPX_RWE]], $_[SPX_FD], 1) == 1)
		? IS_TRUE
		: IS_FALSE;
}

sub watches
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $what) = @ARGUMENTS;

	return(($this->[ATR_WANTS][$what] eq $this->[ATR_ZEROS])
		? IS_FALSE
		: IS_TRUE);
}

sub are_empty
# /type method
# /effect ""
# //parameters
#	position  +multiple
# //returns
#	::Personality::Abstract::Boolean
{
	my $this = shift(\@ARGUMENTS);

	my $empty_or_not = IS_TRUE;
	foreach (@ARGUMENTS)
	{
		next if ($this->[ATR_WANTS][$_] eq $this->[ATR_ZEROS]);
		$empty_or_not = IS_FALSE;
		last;
	}
	return($empty_or_not);
}


#sub visited_all {
#	my ($this, $what) = @ARGUMENTS;
#
#	my $rv =(((not defined($this->[ATR_GOT][PDX_SELECS_READ]) or
#			   ($this->[ATR_GOT][PDX_SELECS_READ] eq $this->[ATR_ZEROS])) and
#			  (not defined($this->[ATR_GOT][PDX_SELECS_WRITE]) or
#			   ($this->[ATR_GOT][PDX_SELECS_WRITE] eq $this->[ATR_ZEROS])) and
#		  (not defined($this->[ATR_GOT][PDX_SELECS_EXCEPTION]) or
#		   ($this->[ATR_GOT][PDX_SELECS_EXCEPTION] eq $this->[ATR_ZEROS])))
#		? IS_TRUE : IS_FALSE);
#	return($rv);
#}

sub validate_target_fhs
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $target (@{$this->[ATR_TARGETS]})
	{
		next unless (defined($target));
		$target->hit(3); # evt_io_validate_fh
	}
	return;
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_GOT][PDX_SELECS_READ] = $this->[ATR_ZEROS];
	$this->[ATR_GOT][PDX_SELECS_WRITE] = $this->[ATR_ZEROS];
	$this->[ATR_GOT][PDX_SELECS_EXCEPTION] = $this->[ATR_ZEROS];
	return;
}

#sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
#	my ($this) = @ARGUMENTS;
#
#	if (defined($loop))
#	{
#		$loop->deregister($this);
#		$loop = IS_UNDEFINED;
#	}
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.101
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"