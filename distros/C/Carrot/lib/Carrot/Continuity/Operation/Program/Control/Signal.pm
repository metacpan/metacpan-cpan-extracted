package Carrot::Continuity::Operation::Program::Control::Signal
# /type class
# /implements [=project_pkg=]::_Plugin_Prototype
# /attribute_type ::Many_Declared::Ordered
# /capability "Program termination by signal."
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$expressiveness->class_names->provide(
		my $signal_target_class =
			'::Continuity::Coordination::Episode::Target::Signal');

	$customized_settings->provide_plain_value(
		my $default_name = 'default_name');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	information_barb
#	signal_name
# //returns
{
	my ($this, $information_barb, $signal_name) = @ARGUMENTS;

#	$loop->construct_standard_episode(
#		'::Target::Signal', $this, $signal_name // $default_name);
	my $signal = $signal_target_class->indirect_constructor(
		$this,
		'evt_signal_any',
		$signal_name // $default_name);

	$this->[ATR_SIGNAL] = $signal;

	return;
}

sub activate
# /type implementation
{
	$_[THIS][ATR_SIGNAL]->activate;
	return;
}

sub deactivate
# /type implementation
{
	$_[THIS][ATR_SIGNAL]->deactivate;
	return;
}

sub evt_signal_any
# /type method
# /effect "Processes the event of a termination signal (SIGTERM)."
# //parameters
# //returns
{
	$loop->leave;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.66
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"