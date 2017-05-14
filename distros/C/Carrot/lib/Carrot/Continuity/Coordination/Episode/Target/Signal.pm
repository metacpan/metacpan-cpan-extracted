package Carrot::Continuity::Coordination::Episode::Target::Signal
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide_instance(
		my $source = '[=project_pkg=]::Source::Signals');

	my $default_name = 'evt_signal';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that            ::Personality::Abstract::Instance
#	name
#	signal
# //returns
{
	my ($this, $that, $name, $signal) = @ARGUMENTS;

	my $callback = $this->create_callback(
		$that,
		$default_name.'_'.lc($signal),
		$name);
	@$this = ($that, $callback, $signal, IS_FALSE, IS_UNDEFINED);
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
#	version 1.1.65
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"