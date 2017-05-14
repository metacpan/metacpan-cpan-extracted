package Carrot::Continuity::Coordination::Episode::Target::Periodic
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time');

	$expressiveness->class_names->provide_instance(
		my $source = '[=project_pkg=]::Source::Time');

	my $default_name = 'evt_time_periodic';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that            ::Personality::Abstract::Instance
#	name
#	period
# //returns
{
	my ($this, $that, $name, $period) = @ARGUMENTS;

	my $callback = $this->create_callback($that, $default_name, $name);
	@$this = ($that, $callback, IS_UNDEFINED, IS_FALSE, $period);
	return;
}

sub hit
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $rv = &{$this->[ATR_CALLBACK]}($this->[ATR_THAT], @ARGUMENTS);
	$this->reactivate;
	return($rv);
}


sub reactivate
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_VALUE] += $this->[ATR_DATA];
	if ($source->register($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_TRUE;
	}
	return;
}

sub activate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_ACTIVATED]);
	$this->[ATR_VALUE] = $$epoch_time + $this->[ATR_DATA];
	if ($source->register($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_TRUE;
	}
	return;
}


sub deactivate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless ($this->[ATR_ACTIVATED]);
	return unless (defined($source));
	if ($source->deregister($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_FALSE;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.75
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"