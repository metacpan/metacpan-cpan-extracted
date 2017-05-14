package Carrot::Continuity::Coordination::Episode::Source::Time
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $class_names = '::Individuality::Controlled::Class_Names');

	$expressiveness->distinguished_exceptions->provide(
		my $too_far_in_past = 'too_far_in_past');

	$class_names->provide_instance(
		my $loop = '[=project_pkg=]::Loop');
	$class_names->provide(
		'[=component_pkg=]::',
			my $timeline_class = '::Time::Line',
			my $targets_class = '::_Targets');

	sub T_ETERNITY() { 2**31 -1; };

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TARGETS] = {};
	$this->[ATR_TIMELINE] = $timeline_class->indirect_constructor(
		[T_ETERNITY]);

	$loop->register($this);
	return;
}

sub max_timeout
# /type method
# /effect ""
# //parameters
#	timeout         ::Personality::Abstract::Seconds
# //returns
#	?
{
	if ($#{$_[THIS][ATR_TIMELINE]} > 0)
	{
		return($_[THIS][ATR_TIMELINE][ADX_FIRST_ELEMENT] - $$epoch_time);
	} else {
		return($_[SPX_TIMEOUT]);
	}
}

sub dispatch
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $timeline = $this->[ATR_TIMELINE];

	while ($#$timeline > 0)
	{
		last if ($timeline->[ADX_FIRST_ELEMENT] > $$epoch_time);
		my $t1 = shift(@$timeline);
		my $targets = delete($this->[ATR_TARGETS]{$t1});
		foreach my $target (@{$targets->arrayref})
		{
			$target->hit($t1);
		}
	}
	return;
}

sub register
# /type method
# /effect ""
# //parameters
#	target
#	t1
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $target, $t1) = @ARGUMENTS;

#	if (ASSERTION_FLAG and ($t1 < ($$epoch_time - 3600)))
#	{
#		$too_far_in_past->raise_exception(
#			{+HKY_DEX_BACKTRACK => $t1,
#			 'time' => scalar(localtime($t1))},
#			ERROR_CATEGORY_SETUP);
#	}
	my $targets = $this->[ATR_TARGETS];
	unless (exists($targets->{$t1}))
	{
		$targets->{$t1} = $targets_class->indirect_constructor;
		$this->[ATR_TIMELINE]->insert($t1);
	}
	$targets->{$t1}->add($target);

	return(IS_TRUE);
}

sub deregister
# /type method
# /effect ""
# //parameters
#	target
#	t1
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $target, $t1) = @ARGUMENTS;

	my $targets = $this->[ATR_TARGETS];
	return unless (exists($targets->{$t1}) and defined($targets->{$t1}));
	$targets->{$t1}->remove($target);
	if ($#{$targets->{$t1}} == ADX_NO_ELEMENTS)
	{
		delete($targets->{$t1});
		$this->[ATR_TIMELINE]->remove($t1);
	}
	return(IS_TRUE);
}

#sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
#{
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
#	version 1.1.96
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"