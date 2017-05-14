package Carrot::Meta::Greenhouse
# /type class
# /capability "Load initial classes"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require 5.8.0; # safe signals
		require 5.14.0; # working $EVAL_ERRORS and ${^GLOBAL_PHASE}
		require 5.18.0; # auto-dereferencing of array/hash references
		require Scalar::Util; # for distinguishing blessed from non-blessed references

		package main_ {
			*Carrot::Meta::Greenhouse::MODULE_SEARCH_PATH = *main::INC{ARRAY};
			*Carrot::Meta::Greenhouse::PROGRAM_ARGUMENTS =
				*main::ARGV{ARRAY};
			*Carrot::Meta::Greenhouse::PROGRAM_NAME = *0;
#			*Carrot::Meta::Greenhouse::ARGUMENTS = *_;
		}

		#NOTE: should not be taken seriously, because require() returns
		# nothing, therefore a civilized behaviour is an illusion
		sub PERL_FILE_LOADED() { 1 }
		sub PERL_FILE_RELOAD() { -1 }

		*main::PERL_FILE_LOADED = \&PERL_FILE_LOADED;
	} #BEGIN

	require Carrot::Meta::Greenhouse::Carrot_Arguments;
	my $carrot_arguments = Carrot::Meta::Greenhouse::Carrot_Arguments
		->constructor;
	$carrot_arguments->assign_if_exists('carrot-main', my $carrot_main);
	$PROGRAM_NAME = $carrot_main;

	unless (-f $carrot_main)
	{
		foreach my $directory (@MODULE_SEARCH_PATH)
		{
			my $file_name = "$directory/$carrot_main";
			next unless (-f $file_name);
			$carrot_main = $file_name;
			last;
		}
	}
	my $dot_base = ($carrot_main =~ s{\.\K\w+\z}{}sr);

	$ENV{'HOME'} //= '/';
	load_global_variables("/etc/carrot/global_variables.pl",
		"$dot_base/global_variables.pl",
		"$ENV{'HOME'}/.carrot/global_variables.pl");

	require Carrot::Meta::Greenhouse::Minimal_Constructor;
	require Carrot::Meta::Greenhouse::Compilation_Name;
	require Carrot::Meta::Greenhouse::Static_Flags;

	my $compilation_name = Carrot::Meta::Greenhouse::Compilation_Name
		->constructor;

	load_global_variables("/etc/carrot/global_variables-$$compilation_name.pl",
		"$dot_base/global_variables-$$compilation_name.pl",
		"$ENV{'HOME'}/.carrot/global_variables-$$compilation_name.pl");

	require Carrot::Modularity::Constant::Global::Array_Indices;
	require Carrot::Modularity::Constant::Global::Boolean;
	require Carrot::Modularity::Constant::Global::Result_Indices::Caller;

	require Carrot::Modularity::Constant::Global::Error_Categories::Eval;
	require Carrot::Modularity::Constant::Global::Result_Indices::Index;
	require Carrot::Modularity::Constant::Global::Result_Indices::Localtime;
	require Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Method;
	require Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Class;
	require Carrot::Modularity::Constant::Global::Parameter::Keys::Open;
	require Carrot::Modularity::Constant::Global::Text::Perl_Syntax;
	require Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers;
	require Carrot::Modularity::Constant::Global::Parameter::Keys::Split;
	require Carrot::Modularity::Constant::Global::Result_Indices::Stat;
	require Carrot::Modularity::Constant::Global::Parameter::Indices::Generic::Function;

	require Carrot::Meta::Greenhouse::Shared_Subroutines;
	require Carrot::Meta::Greenhouse::Named_RE;
	require Carrot::Meta::Greenhouse::Package_Loader;
#	require Carrot::Meta::Greenhouse::Manual_Modularity;

	require Carrot::Diversity::English::Regular_Expression;

# =--------------------------------------------------------------------------= #

sub load_global_variables
# /type function
# /effect "Returns the script file name containing the main routine."
# //parameters
#	*	::Personality::Abstract::Text
# //returns
{
	foreach my $global_variables (@_)
	{
		next unless (-f $global_variables);
		require($global_variables);
	}

	return;
}

sub carrot_main
# /type function
# /effect "Returns the script file name containing the main routine."
# //parameters
# //returns
{
	return($carrot_main);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.151
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
