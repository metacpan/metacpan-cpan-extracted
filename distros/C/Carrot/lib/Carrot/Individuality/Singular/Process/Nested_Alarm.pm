package Carrot::Individuality::Singular::Process::Nested_Alarm
# /type class
# /attribute_type ::One_Anonymous::Array
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	use Time::HiRes qw(
		getitimer
		ITIMER_REAL
		setitimer
	);

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $fatal_error = '::Individuality::Singular::Execution::Fatal_Error');

	my $alarm = IS_FALSE;
	my $sig_alrm = IS_UNDEFINED;
	$sig_alrm = sub {
		$alarm = IS_TRUE;
		$OS_SIGNALS{'ALRM'} = $sig_alrm;
		$fatal_error->trigger(
			[caller()],
			\(my $msg = ''),
			ERROR_CATEGORY_OS_SIGNAL_ALARM);
	};
	$OS_SIGNALS{'ALRM'} = $sig_alrm;

	sub IDX_NST_THEN() { 0 }
	sub IDX_NST_REMAINING() { 1 }

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

die('Monadic properties got lost?');

sub occurred
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Seconds
{
	return($alarm);
}

sub activate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
#	seconds         ::Personality::Abstract::Seconds
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $seconds) = @ARGUMENTS;

	$alarm = IS_FALSE;
	my $former = [$$epoch_time, 0];
	if ($#$this > ADX_NO_ELEMENTS)
	{
		my $remaining = getitimer(ITIMER_REAL);
		if ($seconds < $remaining)
		{
			$former->[IDX_NST_REMAINING] = $remaining;
			setitimer(ITIMER_REAL, $seconds);
		}
	} else {
		setitimer(ITIMER_REAL, $seconds);
	}
	push(@$this, $former);

	return($#$this);
}

sub deactivate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
#	which
# //returns
{
	my ($this, $which) = @ARGUMENTS;

	return if ($which > $#$this);
	my $former = pop(@$this);
	if ($former->[1] > 0)
	{
		my $remaining = $former->[IDX_NST_REMAINING] - ($$epoch_time - $former->[IDX_NST_THEN]);
		$remaining = 0.01 if ($remaining <= 0);
		setitimer(ITIMER_REAL, $remaining);
	}
	if ($#$this == ADX_NO_ELEMENTS)
	{
		setitimer(ITIMER_REAL, 0);
		$alarm = IS_FALSE; # reminder only
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.54
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
