package Carrot::Meta::Monad::Shortcuts
# /type library
# //parameters
#	meta_provider  ::Meta::Provider
# /capability "Associate method names with monad providers."
{
	my ($meta_provider) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Shortcuts./manual_modularity.pl');
	} #BEGIN

	my $shortcuts = {
		'parent_classes' => '::Modularity::Object::Parent_Classes',
		'global_constants' => '::Modularity::Constant::Global',
		'local_constants' => '::Modularity::Constant::Local',
		'parental_constants' => '::Modularity::Constant::Parental',
		'scalar_isset_methods' => '::Modularity::Subroutine::Generator::Scalar_Isset_Methods',
	#	'' => '',
		'block_modifiers' => '::Diversity::Block_Modifiers',
		'ordered_attributes' => '::Modularity::Constant::Parental::Ordered_Attributes',
		'localized_messages' => '::Individuality::Controlled::Localized_Messages',
		'distinguished_exceptions' => '::Individuality::Controlled::Distinguished_Exceptions',
		'class_names' => '::Individuality::Controlled::Class_Names',
		'customized_settings' => '::Individuality::Controlled::Customized_Settings',
		'explicit_parental_constants' => '::Modularity::Constant::Parental::Explicit',
	#	'named_data' => '::Individuality::Controlled::Named_Data',

	#	'static_flag' => '::Individuality::Singular::Execution::Static_Flag',
	#	'caller_backtrace' => '::Individuality::Singular::Execution::Caller_Backtrace',
	#	'stderr_redirector' => '::Individuality::Singular::Execution::STDERR_Redirector',
	#	'code_evaluation' => '::Individuality::Singular::Execution::Code_Evaluation',
	#	'method_trace' => '::Individuality::Singular::Execution::Method_Trace',
	#	'fatal_error' => '::Individuality::Singular::Execution::Fatal_Error',
	#	'named_directories' => '::Individuality::Singular::Application::Named_Directories',
	#	'xdbm_keystore' => '::Individuality::Singular::Application::xDBM_Keystore',
	#	'program_arguments' => '::Individuality::Singular::Application::Program_Arguments',
	#	'dbh' => '::Individuality::Singular::Application::DBH',
	#	'logging_channel' => '::Individuality::Singular::Application::Logging_Channel',
	#	'process_id' => '::Individuality::Singular::Process::Id',
	#	'epoch_time' => '::Individuality::Singular::Process::Epoch_Time',
	#	'nested_alarm' => '::Individuality::Singular::Process::Nested_Alarm',
	#	'kindergarden' => '::Individuality::Singular::Process::Kindergarden',
	#	'exit_status' => '::Individuality::Singular::Process::Exit_Status',
	#	'child' => '::Individuality::Singular::Process::Child',
	#	'background' => '::Individuality::Singular::Process::Id::Background',
	#	'pid_file' => '::Individuality::Singular::Process::Id::PID_File',
	};

# =--------------------------------------------------------------------------= #

sub monad_class_by_method
# /type method
# /effect ""
# //parameters
#	method_name
# //returns
#	::Personality::Abstract::Text +undefined
{
	my ($this, $method_name) = @ARGUMENTS;

	if (exists($shortcuts->{$method_name}))
	{
		return($shortcuts->{$method_name});
	} else {
		return(IS_UNDEFINED);
	}
}

sub dot_ini_got_association
# /type class_method
# /effect "Processes an association from an .ini file."
# //parameters
#	name
#	value
# //returns
{
        my ($class, $name, $value) = @ARGUMENTS;

	if (exists($shortcuts->{$name}))
	{
		warn("Overwriting shortcut '$name' with value '$value'.");
	}
	$shortcuts->{$name} = $value;

        return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.110
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
