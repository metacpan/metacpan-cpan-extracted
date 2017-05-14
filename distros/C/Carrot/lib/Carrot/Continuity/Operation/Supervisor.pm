package Carrot::Continuity::Operation::Supervisor
# /type class
# //tabulators
#	::Launcher
# //parent_classes
#NO SUCH THING
#	[=parent_pkg=]::Program::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $launcher_class = '[=this_pkg=]::Launcher');

	$expressiveness->provide(
		'::Individuality::Controlled::',
		my $customized_settings = '::Customized_Settings');

	$customized_settings->provide_value(
		my $launchers = 'launchers');

	$customized_settings->provide_plain_value(
		my $file_name = 'file_name');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	information_barb  ::Personality::Reflective::Information_Barb
# //returns
{
	my ($this, $information_barb) = @ARGUMENTS;

	$this->[ATR_INFORMATIVE_CONTEXT] = $information_barb;
	$this->[ATR_LAUNCHERS] = [];
	$this->[ATR_FEATURES] = [];

	foreach my $name (@{$launchers->first_column_plain})
	{
		my $launcher = $launcher_class->indirect_constructor($name);
		push($this->[ATR_LAUNCHERS], $launcher);
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

	foreach my $launcher (@{$this->[ATR_LAUNCHERS]})
	{
		$launcher->launch;
	}

	return;
}

sub deactivate
# /type method
# /effect "De-activates the main feature of the instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $launcher (@{$this->[ATR_LAUNCHERS]})
	{
		$launcher->halt;
	}

	return;
}

sub evt_signal_chld
# /type method
# /effect "Handles child exits."
# //parameters
#	target
#	count
#	exited_childs
# //returns
{
	my ($this, $target, $count, $exited_childs) = @ARGUMENTS;

	foreach my $launcher (@{$this->[ATR_LAUNCHERS]})
	{
		$launcher->re_launch($exited_childs);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.113
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"