package Carrot::Continuity::Operation::Program
# /type class
# /attribute_type ::Many_Declared::Ordered
# //tabulators
# /capability "(De-)Activates configured plugins for program operation."
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $program_arguments =
			'::Individuality::Singular::Application::Program_Arguments',
		'::Individuality::Controlled::',
			my $class_names = '::Class_Names',
			my $customized_settings = '::Customized_Settings');

	$program_arguments->provide(my $plain_arguments = '');

	$customized_settings->provide_plain_value(
		my $context_name = 'context_name');
	$customized_settings->provide_value(
		my $features = 'features');

	$class_names->provide(
		my $context_class =
			'::Personality::Reflective::Information_Barb');
	$class_names->assign_anchor('::Continuity::Operation::Program');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if ($#$plain_arguments == ADX_NO_ELEMENTS)
	{
		die("Usage: $PROGRAM_NAME  some_program_cfg\n");
	}

#FIXME: awful, should be specified and retrieved accordingly
	my $program_name = $plain_arguments->[ADX_FIRST_ELEMENT];
	$this->[ATR_PROGRAM_NAME] = $program_name;
	$this->[ATR_FEATURES] = [];

#FIXME: fill with application_directories
	my $information_barb = $context_class->indirect_constructor;
	$information_barb->extend(
		$context_name,
		$this);
#FIXME: migrate
#	$information_barb->assign_value('pid', $PROCESS_ID);

	my $plugins = $features->row_1xN_merged(['*', $program_name], 'plugin');
	# /eval_escalation program_plugin_failed
	foreach my $plugin (@$plugins)
	{
		my $feature = $plugin->indirect_instance(
			$class_names,
			$information_barb);
		push($this->[ATR_FEATURES], $feature);
	}

	return;
}

sub run
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	# /eval_escalation feature_activation_failed
	foreach my $feature (@{$this->[ATR_FEATURES]})
	{
		$feature->activate;
	}

	print STDERR "Starting Loop\n";
#	die;
#	return(IS_TRUE);
#	exit;
	$loop->iterate;
	print STDERR "Ending Loop\n";

	foreach my $feature (@{$this->[ATR_FEATURES]})
	{
		$feature->deactivate;
	}

	return(IS_TRUE);
}

sub terminate
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	print STDERR "Leaving Loop\n";
	$loop->leave;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.308
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
