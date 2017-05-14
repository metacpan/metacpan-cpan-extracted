package Carrot::Continuity::Coordination::Episode::Paragraph::Counter::Rate
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Continuity::Coordination::Episode::Target::Time_Boundary::Constants
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $loop = '::Continuity::Coordination::Episode::Loop');
	
# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MINUTE] = [0, 0];
	$this->[ATR_HOUR] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	$this->[ATR_DAY] = [0, 0];
	$this->[ATR_BOUNDARIES] = [0, 0];
	$this->[ATR_EVENT] = $loop->construct_standard_episode(
		'::Target::Time_Boundary', $this, T_BOUNDARY_MINUTE);
	$this->[ATR_EVENT]->activate;

	return;
}

sub evt_time_boundary
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $minute_counter = $this->[ATR_MINUTE];
	$minute_counter->[1] = $minute_counter->[0];
	$this->[ATR_HOUR][0] += $minute_counter->[0];
	$minute_counter->[0] = 0;

	my $hour = $$epoch_time % 3600;
	if ($hour > $this->[ATR_BOUNDARIES][0])
	{
		$this->[ATR_BOUNDARIES][0] = $hour;

		$this->[ATR_DAY][0] =
			numeric_sum(@{$this->[ATR_HOUR]});

		pop($_[THIS][ATR_HOUR]);
		unshift($_[THIS][ATR_HOUR], 0);
	}

	my $day = $$epoch_time % 86400;
	if ($day > $this->[ATR_BOUNDARIES][1])
	{
		$this->[ATR_BOUNDARIES][1] = $day;
		$this->[ATR_DAY][1] = $this->[ATR_DAY][0];
	}
	return;
}

sub increment
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	$_[THIS][ATR_MINUTE][0] += 1;
}

sub previous_minute
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_MINUTE][1]);
}

sub previous_hour
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_HOUR][1]);
}

sub current_hour
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $time_passed = $$epoch_time * ($$epoch_time % 3600) / 3600;
	return($_[THIS][ATR_HOUR][0] / $time_passed);
}

sub previous_24_hours
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_DAY][0]);
}

sub previous_day
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_DAY][1]);
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $unit (ATR_MINUTE, ATR_HOUR, ATR_DAY)
	{
		foreach (@{$this->[$unit]}) { $_ = 0; };
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"