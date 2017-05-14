package Carrot::Continuity::Operation::Supervisor::Process
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Manage child processes of the supervisor"
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$customized_settings->provide_plain_value(
		my $sig_term = 'terminate_signal_number');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	program
#	launcher
# //returns
{
	my ($this, $program, $launcher) = @ARGUMENTS;

	$this->[ATR_PROGRAM] = $program;
	$this->[ATR_LAUNCHER] = $launcher;
	$this->[ATR_PID] = Carrot::Individuality::Singular::Process::Id->constructor(IS_UNDEFINED);
	$this->[ATR_START_TIME] = $$epoch_time;
	$this->[ATR_START_RECENT] = 0;
	$this->[ATR_SIG_TERM] = $sig_term;


	return;
}

sub needs_restart
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(1) unless defined(${$_[THIS][ATR_PID]});
	return($_[THIS][ATR_PID]->is_running);
}

sub has_pid
# /type method
# /effect ""
# //parameters
#	pid
# //returns
#	?
{
	return(defined(${$_[THIS][ATR_PID]}) and
		(${$_[THIS][ATR_PID]} == $_[SPX_PID]));
}

sub terminate
# /type method
# /effect ""
# //parameters
# //returns
{
	return unless (defined(${$_[THIS][ATR_PID]}));
	kill($_[THIS][ATR_SIG_TERM], ${$_[THIS][ATR_PID]});
	return;
}

sub run
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if (($$epoch_time - $this->[ATR_START_TIME]) > 60)
	{
		$this->[ATR_START_RECENT] = 0;
	} elsif ($this->[ATR_START_RECENT] > 3)
	{
		return;
	}

	my $pid = $this->[ATR_LAUNCHER]->fork_method(
		'execute_program',
		$this->[ATR_PROGRAM]);
	$this->[ATR_PID]->assign_value($pid);
	if (($$epoch_time - $this->[ATR_START_TIME]) > 60)
	{
		$this->[ATR_START_TIME] = $$epoch_time;
	}
	$this->[ATR_START_RECENT] += 1;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"