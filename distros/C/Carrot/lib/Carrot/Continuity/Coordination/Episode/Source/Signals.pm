package Carrot::Continuity::Coordination::Episode::Source::Signals
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use POSIX ();

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $class_names = '::Individuality::Controlled::Class_Names');

	$expressiveness->distinguished_exceptions->provide(
		my $disabled_pipe_signal = 'disabled_pipe_signal',
		my $reserved_vtalrm_signal = 'reserved_vtalrm_signal',
		my $os_signal_unknown = 'os_signal_unknown');

	$class_names->provide_instance(
		my $loop = '[=project_pkg=]::Loop');
	$class_names->provide(
		my $targets_class = '[=component_pkg=]::_Targets');

	$OS_SIGNALS{'PIPE'} = 'IGNORE'; # not ignoring would disable the required EPIPE

# =--------------------------------------------------------------------------= #

sub BYS_IDX_FORMER() { 0 };
sub BYS_IDX_TARGETS() { 1 };
sub BYS_IDX_RECEIVED() { 2 };
sub BYS_IDX_DATA() { 3 };

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_BY_SIGNAL] = {};
	$this->[ATR_RECEIVED] = IS_FALSE;

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

sub dispatch
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless ($this->[ATR_RECEIVED]);

	my $signals = $this->[ATR_BY_SIGNAL];
	foreach my $key (keys($signals))
	{
		my $signal = $signals->{$key};
		next if ($signal->[BYS_IDX_RECEIVED] == 0);
		my $data = [
			$signal->[BYS_IDX_RECEIVED],
			[@{$signal->[BYS_IDX_DATA]}]
		];
		$signal->[BYS_IDX_RECEIVED] = 0;
		$signal->[BYS_IDX_DATA] = [];
		foreach my $target (@{$signal->[BYS_IDX_TARGETS]->arrayref})
		{
			$target->hit(@$data);
		}
	}
	$this->[ATR_RECEIVED] = IS_FALSE;
	return;
}

sub register
# /type method
# /effect ""
# //parameters
#	target
#	signal
# //returns
#	?
{
	my ($this, $target, $signal) = @ARGUMENTS;

	if ($signal eq 'PIPE')
	{
		$disabled_pipe_signal->raise_exception(
			{+HKY_DEX_BACKTRACK => $signal,
			 'signal' => $signal},
			ERROR_CATEGORY_SETUP);
	}
	if ($signal eq 'VTALRM')
	{
		$reserved_vtalrm_signal->raise_exception(
			{+HKY_DEX_BACKTRACK => $signal,
			 'signal' => $signal},
			ERROR_CATEGORY_SETUP);
	}
	unless (exists($OS_SIGNALS{$signal}))
	{
		$os_signal_unknown->raise_exception(
			{+HKY_DEX_BACKTRACK => $signal,
			 'signal' => $signal},
			ERROR_CATEGORY_SETUP);
	}

	unless (exists($this->[ATR_BY_SIGNAL]{$signal}))
	{
		my $targets = $targets_class->indirect_constructor;
		$this->[ATR_BY_SIGNAL]{$signal} = [$OS_SIGNALS{$signal}, $targets, 0, []];
#FIXME: change this to POSIX signal handling
		my $handler_method = "SIG${signal}_handler";
		unless ($this->can($handler_method))
		{
			$handler_method = "SIGX_handler";
		}
		$OS_SIGNALS{$signal} = $this->$handler_method($signal);
	}
	$this->[ATR_BY_SIGNAL]{$signal}[BYS_IDX_TARGETS]->add($target);
	return(PERL_FILE_LOADED);
}

sub deregister
# /type method
# /effect ""
# //parameters
#	target
#	signal
# //returns
#	?
{
	my ($this, $target, $signal) = @ARGUMENTS;

	unless (exists($OS_SIGNALS{$signal})) { #ASSERTION#
		$os_signal_unknown->raise_exception(
			{+HKY_DEX_BACKTRACK => $signal,
			 'name' => $signal},
			ERROR_CATEGORY_SETUP);
	}

	my $track = $this->[ATR_BY_SIGNAL]{$signal};
	return unless (defined($track->[BYS_IDX_TARGETS]));
	$track->[BYS_IDX_TARGETS]->remove($target);
	if ($#{$track->[BYS_IDX_TARGETS]} == ADX_NO_ELEMENTS)
	{
		$OS_SIGNALS{$signal} = $track->[BYS_IDX_FORMER];
		delete($this->[ATR_BY_SIGNAL]{$signal});
	}
	return(PERL_FILE_LOADED);
}

sub SIGX_handler
# /type method
# /effect ""
# //parameters
#	signal
# //returns
#	?
{
	my ($this, $signal) = @ARGUMENTS;

	my $handler = IS_UNDEFINED;
	$handler = sub {
		$this->[ATR_BY_SIGNAL]{$signal}[BYS_IDX_RECEIVED] += 1;
		$this->[ATR_RECEIVED] = IS_TRUE;
		$OS_SIGNALS{$signal} = $handler;
	};
	return($handler);
}

sub SIGCHLD_handler
# /type method
# /effect ""
# //parameters
#	signal
# //returns
#	?
{
	my ($this, $signal) = @ARGUMENTS;

	my $handler = IS_UNDEFINED;
	my $by_signal = $this->[ATR_BY_SIGNAL]{'CHLD'};
	my $received = $by_signal->[BYS_IDX_DATA];

	$handler = sub {
#FIXME: unchecked whether the constant exists...
		while ((my $child = POSIX::waitpid(-1, POSIX::WNOHANG)) > 0)
		{
			push($received, [$child, ${^CHILD_ERROR_NATIVE}]);
		}
		$by_signal->[BYS_IDX_RECEIVED] += 1;
		$this->[ATR_RECEIVED] = IS_TRUE;
		$OS_SIGNALS{'CHLD'} = $handler;
	};
	return($handler);
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
#	version 1.1.100
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"