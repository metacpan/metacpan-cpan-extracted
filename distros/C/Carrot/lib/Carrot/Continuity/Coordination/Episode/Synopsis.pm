package Carrot::Continuity::Coordination::Episode::Synopsis
# /type package
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	require Carrot::Continuity::Coordination::Episode::Loop;
	require Time::Local;

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $invalid_relative_unit = 'invalid_relative_unit',
		my $invalid_absolute_unit = 'invalid_absolute_unit');

	my $relative_units = {
		's' => 1,
		'm' => 60,
		'h' => 3600,
		'd' => 86400,
		'w' => 86400 * 7
	};
	my $absolute_prefixes = {
		'second' => 0,
		'minute' => 1,
		'hour' => 2,
		'day' => 3,
		'month' => 4,
		'year' => 5
	};
	my $increments = {
		'time_periodic' => 0,
		'time_wallclock' => 0,
		'time_timeout' => 0,
		'poll_edge' => 0
	};
	my $symbolic_date_re = q{
		^(every|in)\s+(\d+)\s*
		(s(?:econds?)?|m(?:minutes?)?|h(?:hours?)?|d(?:days?)?|w(?:weeks?)?)?$
	};

# =--------------------------------------------------------------------------= #

sub recognize
# /type method
# /effect ""
# //parameters
#	class
#	instance
# //returns
#	?
{
	my ($class, $instance) = splice(\@ARGUMENTS, 0, 2);

	return([map(_recognize($instance, $_), @ARGUMENTS)]);
}

sub _recognize($$)
# /type function
# /effect ""
# //parameters
#	instance
#	value
# //returns
#	::Personality::Abstract::Instance
{
	my ($instance, $value) = @ARGUMENTS;

	if (ref($value) eq 'CODE')
	{
		$increments->{'poll_edge'} += 1;
		return($loop->construct_episode(
			'::Paragraph::Poll_Edge', $instance,
			"_test$increments->{'poll_edge'}", $value, 2));
	} elsif (length($value) == 1)
	{
		return($loop->construct_episode(
			'::Target::Time_Boundary', $instance, IS_UNDEFINED, $value));
	} elsif ($value =~ m{$symbolic_date_re}sgix)
	{
		my ($mode, $seconds, $unit) = ($1, $2, substr($3, 0, 1));
		$unit //= 's';
		unless (exists($relative_units->{$unit}))
		{
			$invalid_relative_unit->raise_exception(
				{'unit' => $unit},
				ERROR_CATEGORY_SETUP);
		}
		$seconds *= $relative_units->{$unit};
		$seconds = 10 if ($seconds < 1);
		if ($mode eq 'every')
		{
			my $ext = (($increments->{'time_periodic'}++ == 0) ? undef : "_$increments->{'time_periodic'}");
			return($loop->construct_episode(
				'::Target::Periodic', $instance, $ext, $seconds));
		} else { # 'in'
			my $ext = (($increments->{'time_timeout'}++ == 0) ? undef : "_$increments->{'time_timeout'}");
			return($loop->construct_episode(
				'::Target::Timeout', $instance, $ext, $seconds));
		}
	} elsif ($value =~ s{^at\h+}{}sg)
	{
		my $e = [];
		while ($value =~ s{^\h*(second|minute|hour|day|month|year)\h+(\d{1,4})}{}sg)
		{
			push($e, [$2, $1]);
		}
		my $ext = (($increments->{'time_wallclock'}++ == 0) ? undef : "_$increments->{'time_wallclock'}");
		my $seconds = postfix_date_format(@$e);
		return($loop->construct_episode(
			'::Target::Wallclock', $instance, $ext, $seconds));
	} elsif ($value =~ m{^(SIG)(\w+)$}sgi)
	{
		return($loop->construct_episode(
			'::Target::Signal', $instance, IS_UNDEFINED, $2));
	} elsif (defined(fileno($value)))
	{
		return($loop->construct_episode(
			'::Target::FD_Nonstop_IO', $instance, IS_UNDEFINED, $value));
	}
}

sub postfix_date_format
{
	my $now = [Time::Local::localtime(time)];
	$now->[4] -= 1;
	$now->[1] += 1; # next minute only
	foreach my $element (@ARGUMENTS)
	{
		my ($value, $unit) = @$element;
		unless (exists($absolute_prefixes->{$unit}))
		{
			$invalid_absolute_unit->raise_exception(
				{+HKY_DEX_BACKTRACK => $element,
				 'unit' => $element},
				ERROR_CATEGORY_SETUP);
		}
		$now->[$absolute_prefixes->{$unit}] = $value;
	}
	$now->[4] += 1;
	my $seconds = Time::Local::timelocal(@now);
	return($seconds);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.57
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
