package Carrot::Continuity::Operation::Supervisor::Launcher
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $process_id_class = '::Individuality::Singular::Process::Id');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	name
# //returns
{
	my ($this, $name) = @ARGUMENTS;

	$this->[ATR_NAME] = $name;
	$this->[ATR_PID] = $process_id_class->indirect_constructor;
	$this->[ATR_PLUGINS] = [];

	my $plugins = $launchers->row_1xN_merged(
		['*', $this->[ATR_NAME]],
		'plugin');
	foreach my $plugin (@$plugins)
	{
		my $feature = $plugin->indirect_instance(
			$class_names,
			$information_barb);
		push($this->[ATR_PLUGINS], $feature);
	}

	return;
}

sub launch
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

#FIXME: use new ::Id::Child
	return if ($this->[ATR_PID]->fork < 0);
	foreach my $plugin (@{$this->[ATR_PLUGINS]})
	{
		$plugin->effect;
	}
	exec
# exec external script or class

	exit;
}

sub halt
# /type method
# /effect ""
# //parameters
#	parent_pid
#	program
# //returns
{
	my ($this) = @ARGUMENTS;

#FIXME
	$this->[ATR_PID]->send_signal('terminate');

	return;
}

sub re_launch
# /type method
# /effect ""
# //parameters
#	childs_exited
# //returns
{
	my ($this, $childs_exited) = @ARGUMENTS;

	$this->[ATR_PID]->send_signal('terminate');

	return;
{# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.69
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"