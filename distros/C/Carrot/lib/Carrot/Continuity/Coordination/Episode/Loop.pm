package Carrot::Continuity::Coordination::Episode::Loop
# /type class
# /instances singular
# /project_entry [=parent_pkg=]
# /attribute_type ::Many_Declared::Ordered
# /capability "The standard main event loop."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		my $expressiveness = Carrot::modularity;
		$expressiveness->package_resolver->provide(
			my $episode = 'Carrot::Continuity::Coordination::Episode');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $class_names = '::Individuality::Controlled::Class_Names',
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$class_names->assign_anchor('[=project_pkg=]');

	$distinguished_exceptions->provide(
		my $non_reentrant = 'non_reentrant');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub T_ETERNITY() { 2**31 -1; };

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	timeout         ::Personality::Abstract::Seconds
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MAX_TIMEOUT] = exists($_[SPX_TIMEOUT])
		? $_[SPX_TIMEOUT]
		: T_ETERNITY;

	$this->[ATR_SOURCES] = [];
	$this->[ATR_CONTINUE] = IS_FALSE;
	$this->[ATR_RUNNING] = IS_FALSE;

	return;
}

sub construct_episode
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $this = shift(\@ARGUMENTS);

	return($class_names->indirect_instance(@ARGUMENTS));
}

sub construct_standard_episode
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	that            ::Personality::Abstract::Instance
#	*
# //returns
#	::Personality::Abstract::Instance
{
	my ($this, $pkg_name, $that) = splice(\@ARGUMENTS, 0, 3);

	return($class_names->indirect_instance(
		       $pkg_name,
		       $that,
		       IS_UNDEFINED,
		       @ARGUMENTS));
}

sub register
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	#FIXME: should this become a role?
	if ($source->can('priority_high'))
	{
		unshift($this->[ATR_SOURCES], $source);
	} else {
		push($this->[ATR_SOURCES], $source);
	}
	return;
}

sub deregister
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	foreach my $registered_source (splice($this->[ATR_SOURCES]))
	{
		next unless (defined($registered_source)); #global destruction?
		next if ($registered_source->is_itself($source)),
		push($this->[ATR_SOURCES], $registered_source);
	}
	return;
}

sub leave
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_CONTINUE] = IS_FALSE;
	return;
}

sub is_running
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][ATR_RUNNING]);
}

sub iterate
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if ($this->[ATR_RUNNING])
	{
		$non_reentrant->raise_exception(
			{},
			ERROR_CATEGORY_IMPLEMENTATION);
	}

	my $sources = $this->[ATR_SOURCES];
	return if ($#$sources == ADX_NO_ELEMENTS);

	$this->[ATR_RUNNING] = IS_TRUE;
	$this->[ATR_CONTINUE] = IS_TRUE;
	while ($this->[ATR_CONTINUE])
	{
		my $timeout = $this->[ATR_MAX_TIMEOUT];
		$epoch_time->update;
		foreach my $source (@$sources)
		{
			my $t1 = $source->max_timeout($timeout);
			$timeout = restrict_to_positive_maximum($t1, $timeout);
			last if ($timeout == 0);
		}

		$sources->[ADX_FIRST_ELEMENT]->await($timeout);

		$epoch_time->update;
		foreach my $source (@$sources)
		{
			$source->dispatch;
		}
	}
	$this->[ATR_CONTINUE] = IS_FALSE;
	$this->[ATR_RUNNING] = IS_FALSE;

	return;
}

sub restrict_to_positive_maximum
# /type function
# /effect ""
# //parameters
#	value
#	upper_limit
# //returns
#	::Personality::Abstract::Number
{
	return(($_[SPX_VALUE] > $_[SPX_UPPER_LIMIT])
		? $_[SPX_UPPER_LIMIT]
		: (($_[SPX_VALUE] < 0)
			? 0
			: $_[SPX_VALUE]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.123
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"