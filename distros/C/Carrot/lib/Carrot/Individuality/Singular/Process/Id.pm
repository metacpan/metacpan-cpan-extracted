package Carrot::Individuality::Singular::Process::Id
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
#FIXME: result of a blind conversion - looks not correct
		my $local_episode_class = '::Continuity::Coordination::Episode::Local',
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');
	#	my $kindergarden = '::Individuality::Singular::Process::Kindergarden');

#FIXME:
	$distinguished_exceptions->provide(
		my $perl_fork_failed = 'perl_fork_failed',
		my $perl_setxid_failed = 'perl_setxid_failed');

	my $local_subscription = $local_episode->indirect_constructor;
	$local_subscription->register_event('pid_change');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	my ($this) = @ARGUMENTS;

	$$this = (exists($_[SPX_PID]) ? $_[SPX_PID] : $PROCESS_PID);
	return;
}

sub subscribe_pid_change
# /type method
# /effect ""
# //parameters
#	instance  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$local_subscription->subscribe('pid_change', @ARGUMENTS);
	return;
}

sub unsubscribe_pid_change
# /type method
# /effect ""
# //parameters
#	instance  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$local_subscription->unsubscribe('pid_change', @ARGUMENTS);
	return;
}


sub update
# /type method
# /effect ""
# //parameters
# //returns
{
	return if (${$_[THIS]} == $PROCESS_PID);
	${$_[THIS]} = $PROCESS_ID;
	$local_subscription->trigger_event('pid_change');
	return;
}

sub fork
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $parent_pid = $PROCESS_ID;

	#FIXME: use $fatal_syscalls
	my $child_pid = CORE::fork();
	unless (defined($child_pid))
	{
		$perl_fork_failed->raise_exception(
			{'pid' => $PROCESS_ID,
			 'name' => $PROGRAM_NAME,
			 'os_error' => $OS_ERROR},
			ERROR_CATEGORY_OS);
	}

	if ($child_pid > 0)
	{
		return($child_pid);
	} else {
		$_[THIS]->update;
		return(-$parent_pid);
	}
}

sub set_name
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	$PROGRAM_NAME = $_[SPX_NAME];
	return;
}
sub get_name
# /type function
# /effect ""
# //parameters
# //returns
#	?
{
	return($PROGRAM_NAME);
}

sub is_running
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	kill(0, ${$_[THIS]});
}

sub send_signal
# /type method
# /effect ""
# //parameters
#	signal
# //returns
#	?
{
	kill($_[SPX_SIGNAL], ${$_[THIS]});
}

sub id_changed
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(IS_FALSE) if (defined($$this) and ($$this == $PROCESS_PID));
	$$this = $PROCESS_PID;
	return(IS_TRUE);
}

sub gone_or_kill
# /type method
# /effect ""
# //parameters
#	timeout         ::Personality::Abstract::Seconds
# //returns
#	?
{ # FIXME: convert this to POSIX-style
  # FIXME: the return value is weird
	my ($this, $timeout) = @ARGUMENTS;

	while ($timeout > 0)
	{
		return(IS_TRUE) unless (kill(0, $$this));
		sleep(1);
		$timeout -= 1;
	}
	return(kill(9, $$this));
}

sub set_ugid
# /type method
# /effect ""
# //parameters
#	uid
#	gid
# //returns
{
	my ($this, $uid, $gid) = @ARGUMENTS;

	if (defined($uid) and ($REAL_USER_ID != $EFFECTIVE_USER_ID))
	{
		my $former = $REAL_USER_ID;
		$REAL_USER_ID = $uid;
		if ($OS_ERROR > 0)
		{
			$perl_setxid_failed->raise_exception(
				{+HKY_DEX_BACKTRACK => $uid,
				 'x' => 'u',
				 'xid' => $uid,
				 'former_xid' => $former,
				 'os_error' => $OS_ERROR},
				ERROR_CATEGORY_SETUP);
		}
	}
	if (defined($gid) and ($REAL_GROUP_ID != $EFFECTIVE_GROUP_ID))
	{
		my $former = $REAL_GROUP_ID;
		$REAL_GROUP_ID = $gid;
		if ($OS_ERROR > 0)
		{
			$perl_setxid_failed->raise_exception(
				{+HKY_DEX_BACKTRACK => $gid,
				 'x' => 'g',
				 'xid' => $gid,
				 'former_xid' => $former,
				 'os_error' => $OS_ERROR},
				ERROR_CATEGORY_SETUP);
		}
	}
	return;
}

sub set_eugid
# /type method
# /effect ""
# //parameters
#	uid
#	gid
# //returns
{
	my ($this, $uid, $gid) = @ARGUMENTS;

	if (defined($uid) and ($EFFECTIVE_USER_ID != $uid))
	{
		my $former = $EFFECTIVE_USER_ID;
		$EFFECTIVE_USER_ID = $uid;
		if ($OS_ERROR > 0)
		{
			$perl_setxid_failed->raise_exception(
				{+HKY_DEX_BACKTRACK => $uid,
				 'x' => 'u',
				 'xid' => $uid,
				 'former_xid' => $former,
				 'os_error' => $OS_ERROR},
				ERROR_CATEGORY_SETUP);
		}
	}
	if (defined($gid) and ($EFFECTIVE_GROUP_ID != $gid))
	{
		my $former = $EFFECTIVE_GROUP_ID;
		$EFFECTIVE_GROUP_ID = $gid;
		if ($OS_ERROR > 0)
		{
			$perl_setxid_failed->raise_exception(
				{+HKY_DEX_BACKTRACK => $gid,
				 'x' => 'g',
				 'xid' => $gid,
				 'former_xid' => $former,
				 'os_error' => $OS_ERROR},
				ERROR_CATEGORY_SETUP);
		}
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.87
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"