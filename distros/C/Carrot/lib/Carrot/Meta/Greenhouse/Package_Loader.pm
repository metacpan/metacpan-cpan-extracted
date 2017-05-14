package Carrot::Meta::Greenhouse::Package_Loader
# /type library
# /capability "Load packages by name"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Package_Loader./manual_modularity.pl');
	} #BEGIN

	require Carrot::Modularity::Package::Patterns;
	my $pkg_patterns =
		Carrot::Modularity::Package::Patterns->constructor;

	require Carrot::Modularity::Package::Event::Generic;
	my $generic_events =
		Carrot::Modularity::Package::Event::Generic->constructor;

	require Carrot::Modularity::Package::Event::Specific;
	my $specific_events =
		Carrot::Modularity::Package::Event::Specific->constructor;
	$generic_events->subscribe_after($specific_events);

	@ARGUMENTS = ($generic_events);
	require Carrot::Modularity::Package::Loader;
	my $loader =
		Carrot::Modularity::Package::Loader->constructor;

	require Carrot::Meta::Greenhouse::Translated_Errors;
	my $translated_errors =
		Carrot::Meta::Greenhouse::Translated_Errors->constructor;

	my $pending = {};
	my $no_instances = {};
	my $singular_instances = {
		'Carrot::Modularity::Package::Patterns' => $pkg_patterns,
		'Carrot::Modularity::Package::Event::Generic' => $generic_events,
		'Carrot::Modularity::Package::Event::Specific' => $specific_events,
		'Carrot::Modularity::Package::Loader' => $loader,
		'Carrot::Meta::Greenhouse::Translated_Errors' => $translated_errors,
	};

# =--------------------------------------------------------------------------= #

sub provide
# /type function
# /effect "Loads packages given by name"
# //parameters
#	pkg_name  +multiple
# //returns
{
	foreach my $pkg_name (@ARGUMENTS)
	{
		$pkg_patterns->qualify_package_name($pkg_name, 'Carrot');
		$loader->load($pkg_name);
	}
	return;
}

sub provide_instance
# /type function
# /effect "Provides instances of the classes given by name"
# //parameters
#	pkg_name  +multiple
# //returns
{
	provide(@ARGUMENTS);
	foreach my $pkg_name (@ARGUMENTS)
	{
# justified, because Carrot::Meta::Greenhouse::Package_Loader is a combination of Provider and Resolver
		$pkg_name = create_instance($pkg_name);
	}
	return;
}

sub create_instance
# /type function
# /effect "Constructs an instance or take a previously constructed"
# //parameters
#	pkg_name
#	*
# //returns
#	::Personality::Abstract::Instance
{
	my $pkg_name = shift(\@ARGUMENTS);

	if (exists($singular_instances->{$pkg_name}))
	{
		if (defined($singular_instances->{$pkg_name}))
		{
			if (@ARGUMENTS)
			{
				$translated_errors->oppose(
					'reloading_singluar',
					[$pkg_name]);
			}
		} else {
			$singular_instances->{$pkg_name} =
				$pkg_name->constructor(@ARGUMENTS);
		}
		return($singular_instances->{$pkg_name});

	} else {
		if (exists($no_instances->{$pkg_name}))
		{
			$translated_errors->oppose(
				'reloading_singluar',
				[$pkg_name]);
		}
		return($pkg_name->constructor(@ARGUMENTS));
	}
}

sub create_pending_instance
# /type function
# /effect "Constructs an instance for a package marked as pending"
# //parameters
#	pkg_name
# //returns
{
	my ($pkg_name) = @ARGUMENTS;

	unless (exists($pending->{$pkg_name}))
	{
		$translated_errors->oppose(
			'package_loading_not_pending',
			[$pkg_name]);
	}
	my $pkg_ref = delete($pending->{$pkg_name});
	$$pkg_ref = $pkg_name->constructor;
	return;
}

sub provide_instance_soonest
# /type function
# /effect "Provide a instances of the given packages as soon as they"re loaded'
# //parameters
#	pkg_name  +multiple
# //returns
{
	foreach my $pkg_name (@ARGUMENTS)
	{
		$pending->{$pkg_name} = \$pkg_name;
		$specific_events->subscribe_callback(
			$pkg_name, \&create_pending_instance);
#		$pkg_name = IS_UNDEFINED;
	}
	return;
}

sub mark_singular
# /type function
# /effect "Marks a package for singular instances."
# //parameters
#	pkg_name
# //returns
{
	my $pkg_name = (caller)[RDX_CALLER_PACKAGE];
	unless (exists($singular_instances->{$pkg_name}))
	{
		$singular_instances->{$pkg_name} = IS_UNDEFINED;
	}
	return;
}

sub mark_no
# /type function
# /effect "Marks a package for singular instances."
# //parameters
#	pkg_name
# //returns
{
	my $pkg_name = (caller)[RDX_CALLER_PACKAGE];
	$no_instances->{$pkg_name} = IS_EXISTENT;
	return;
}

# sub load_before_bless
# # /type function
# # /effect ""
# # //parameters
# #	<reference>
# #	<pkg_name>
# # //returns
# {
# 	my ($reference, $pkg_name) = @ARGUMENTS;
#
# 	$loader->load($pkg_name);
# 	return(bless($reference, $pkg_name));
# }

sub dot_ini_got_package_name
# /type class_method
# /effect "Processes a package name from a .ini file."
# //parameters
#	class
#	package_name
# //returns
{
	my ($class, $package_name) = @ARGUMENTS;

	$package_name->load;
#	my $pkg_name = $package_name->value;
#	$singular_instances->{$pkg_name} = provide_instance_soonest($pkg_name);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.226
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
