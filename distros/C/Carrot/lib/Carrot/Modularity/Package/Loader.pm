package Carrot::Modularity::Package::Loader
# /type class
# /capability ""
{
	my ($generic_events) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Loader./manual_modularity.pl');
	} #BEGIN

	require Carrot::Modularity::Package::Patterns;
	my $pkg_patterns =
		Carrot::Modularity::Package::Patterns->constructor;

	require Carrot::Personality::Valued::Perl5::Eval_Error;
	my $eval_error_class = 'Carrot::Personality::Valued::Perl5::Eval_Error';

	require Carrot::Modularity::Package::File_Name::Qualification;
	my $search_path =
		Carrot::Modularity::Package::File_Name::Qualification->constructor;

	require Carrot::Meta::Greenhouse::Translated_Errors;
	my $translated_errors =
		Carrot::Meta::Greenhouse::Translated_Errors->constructor;

	if (TRACE_FLAG)
	{
		my $modules_loaded = [];
		foreach my $key (sort(keys(%MODULES_LOADED)))
		{
			next if ($key =~ m{\./manual_modularity.pl\z});
			if ($key =~ m{\ACarrot})
			{
				push($modules_loaded, $key);
			} else {
				print STDERR "  PRE loaded  $key\n";
			}
		}
		foreach my $key (@$modules_loaded)
		{
			print STDERR "  PRE loaded  $key\n";
		}
	}

	my $pending = 0;
	my $mappings = [];
	#my $CNI = {};
	#while (my ($key, $absolute) = each(%MODULES_LOADED)) {
	#	$CNI->{$absolute} = IS_EXISTENT;
	#}

# =--------------------------------------------------------------------------= #

sub load
# /type method
# /effect ""
# //parameters
#	pkg_name
#	*
# //returns
{
	my ($this, $pkg_name) = splice(\@ARGUMENTS, 0, 2);

	my $pkg_file = $pkg_patterns->package_as_file_name($pkg_name);
	$this->rewrite($pkg_file) if (MAP_FLAG); # this is development

	if (exists($MODULES_LOADED{$pkg_file}))
	{
		if (@ARGUMENTS) # arguments can only be passed for first time loading
		{
			$translated_errors->oppose(
				'package_already_loaded',
				[$pkg_name]);
		}
		return;
	}
	my $relative_file = $pkg_file;
	unless ($search_path->qualify_first($pkg_file))
	{
		$translated_errors->oppose(
			'non_existent_package_file',
			[$pkg_file, $search_path->as_list]);
	}
	if (exists($MODULES_LOADED{$pkg_file}))
	{
		if (@ARGUMENTS) # arguments can only be passed for first time loading
		{
			$translated_errors->oppose(
				'package_already_loaded',
				[$pkg_name]);
		}
		return;
	}
#	if (SHADOW_FLAG)
#	{
#		my $shadow_file = ($pkg_file =~ s{\.\Kpm\z}{}sr).'/shadow-manual.pm';
#		if (-f $shadow_file)
#		{
#			$pkg_file = $shadow_file;
#		}
#	}

#	$MODULES_LOADED{$relative_file} = IS_UNDEFINED;
	#FIXME: enables finding the dot directory, but should be undefined
	$MODULES_LOADED{$relative_file} = $pkg_file;

	my $indent = '| ' x $pending;
	print STDERR "START loading $indent$pkg_name\n" if (TRACE_FLAG);
	$pending += 1;
	$generic_events->evt_package_load_before($pkg_name, $pkg_file);
#	my $eval_error = $eval_error_class->constructor;
	my $rv;
	eval {
		{
			no strict 'refs';
			*{$pkg_name.'::PERL_FILE_LOADED'} =
				\&Carrot::Meta::Greenhouse::PERL_FILE_LOADED;
		}
		$rv = require($pkg_file);
		# maintain entries in a compatible way
		$MODULES_LOADED{$relative_file} = delete($MODULES_LOADED{$pkg_file});

		return(IS_TRUE);
	} or do {
		delete($MODULES_LOADED{$pkg_file});
		$translated_errors->escalate(
			'package_loading_failed',
			[$pkg_name, $pkg_file],
			$EVAL_ERROR);
	};
#	} or $eval_error->failure($EVAL_ERROR);
	{
		no strict 'refs';
		undef *{$pkg_name.'::PERL_FILE_LOADED'};
	}
	$pending -= 1;

#	if ($EVAL_ERROR) #$eval_error->is_failure)
#	{
#		print STDERR " FAIL loading $indent$pkg_file\n" if (TRACE_FLAG);
##		$eval_error->escalate;
#		die($EVAL_ERROR);
#	}

	print STDERR "  END loading $indent^\n" if (TRACE_FLAG);
	$generic_events->evt_package_load_after($pkg_name);
	return($rv);
}

sub rewrite
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	my ($this, $pkg_file) = @ARGUMENTS;

	foreach my $mapping (@$mappings)
	{
		my ($name, $length, $value) = @$mapping;
		next unless (substr($pkg_file, 0, $length) eq $name);
		$_[SPX_PKG_FILE] = $value;
		last;
	}
	return;
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

	push($mappings, [$name, length($name), $value]);

	return;
}

#FIXME: purely theoretic, delete_package() isn't meant for re-loading
#	kept here as a counter-indication
#require Symbol;
#sub re_load
#{
#	my $this = shift(\@ARGUMENTS);
#
#	my $pkg_name = $$this;
#	if (exists($LOADED{$pkg_name}))
#	{
#		delete($LOADED{$pkg_name});
#		Symbol::delete_package($pkg_name);
#		delete($MODULES_LOADED{$this->file_name_relative});
#	}
#	return($this->load(@ARGUMENTS));
#}

#sub already_loaded
#{
#	my ($this, $pkg_file) = @ARGUMENTS;
#
#	if (exists($MODULES_LOADED{$pkg_file}))
#	{
#		return(IS_TRUE);
#	}
#	while (my ($key, $absolute) = each(%MODULES_LOADED))
#	{
#		next if ($absolute ne $pkg_file);
#		return(IS_TRUE);
#	}
#	return(IS_FALSE);
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.449
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
