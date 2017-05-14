package Carrot::Individuality::Singular::Process::Kindergarden
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');
	$expressiveness->class_names->provide(
		my $array_class = '::Personality::Elemental::Array::Numbers');

	$distinguished_exceptions->provide(
		my $process_child_failed = 'process_child_failed');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

#FIXME: this is wild and take some effort to pull straight
sub EXI_IDX_PID() { 0 }
sub EXI_IDX_TRIES() { 1 }

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CHILDREN] = $array_class->indirect_constructor;
	$this->[ATR_EXITED] = [];
	$this->[ATR_FORCE_OUT] = [];

	my $signal_event = $loop->construct_standard_episode(
		'::Target::Signal', $this, 'CHLD');
	$this->[ATR_SIGCHLD] = $signal_event;

	my $periodic_event = $loop->construct_standard_episode(
		'::Target::Periodic', $this, 5);
	$this->[ATR_PERIODIC] = $periodic_event;

	$signal_event->activate;
	$periodic_event->activate;

	return;
}

sub admit
# /type method
# /effect ""
# //parameters
#	pid
# //returns
{
	push($_[THIS][ATR_CHILDREN], $_[SPX_PID]);
	return;
}

sub collect_fatally
# /type method
# /effect ""
# //parameters
#	pid
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $pid) = @ARGUMENTS;

	my $exit_code = $this->collect($pid);
	if ($exit_code > 0)
	{
		$process_child_failed->raise_exception(
#FIXME: not very helpful without a programm name
			{'pid' => $pid,
			 'exit_code' => $exit_code},
			ERROR_CATEGORY_SETUP);
	}

	return($exit_code);
}

sub collect
# /type method
# /effect ""
# //parameters
#	pid
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $pid) = @ARGUMENTS;

	my $exit_code = -1;
	my $retried = IS_FALSE;
RETRY:	foreach my $child (splice($this->[ATR_EXITED]))
	{
		my ($exited_pid, $exited_code) = @$child;
		if ($exited_pid == $pid)
		{
			$exit_code = $exited_code;
		} else {
			push($this->[ATR_EXITED], $child);
		}
	}
	return($exit_code) if ($exit_code > 0);

	if (not $this->[ATR_CHILDREN]->contains($pid))
	{
		if ($retried)
		{
			return(IS_UNDEFINED);
		} else {
			$retried = IS_TRUE;
			# Time passes between the tests for EXITED and CHILDREN.
			# In between the child could have exited.
			# Therefore a second try.
			# However, the pid could have been re-used already,
			# referring to a different child. So many race
			# conditions, so little time.
			goto RETRY;
		}
	}

	kill('TERM', $pid);
	push($this->[ATR_FORCE_OUT], [$pid, 2]);

	return($exit_code);
}

sub has_exited
# /type method
# /effect ""
# //parameters
#	pid
# //returns
#	::Personality::Abstract::Boolean
{
	#NOTE: efficient enough, ATR_EXITED normally is empty
	return(grep(($_->[EXI_IDX_PID] == $_[SPX_PID]), @{$_[THIS][ATR_EXITED]}) > 0);
}

sub evt_time_periodic
# /type method
# /effect "Act on a periodic time event."
# //parameters
#	target
# //returns
{
	my ($this, $target) = @ARGUMENTS;

	return if ($#{$this->[ATR_FORCE_OUT]} == ADX_NO_ELEMENTS);

	foreach my $child (splice($this->[ATR_FORCE_OUT]))
	{
		my ($pid, $tries) = @$child;
		next if ($this->has_exited($pid));
		next unless (kill($pid, 0)); # isn't running
		if ($tries > 1)
		{
			$child->[EXI_IDX_TRIES] -= 1;
			push($this->[ATR_FORCE_OUT], $child);
			next;
		}
		# no point in sending SIGKILL more than once
		kill('KILL', $pid);
	}
	return;
}

sub evt_signal_chld
# /type method
# /effect ""
# //parameters
#	target
#	count
#	exited_childs
# //returns
{
	push($_[THIS][ATR_EXITED], @{$_[SPX_EXITED_CHILDS]});
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.76
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"