package Carrot::Meta::Greenhouse::Dot_Ini::Line
# /type class
# /capability "Recognition of line patterns in .ini files"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Dot_Ini/Line./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $pkg_hierarchy_class = '::Modularity::Package::Expander::Hierarchy',
		my $pkg_level_class = '::Modularity::Package::Expander::Level');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $package_resolver = '::Modularity::Package::Resolver');

	$package_resolver->provide(
		my $package_name_class = '::Modularity::Package::Name',
		'::Personality::Valued::File::Name::Type::',
			my $directory_class = '::Directory',
			my $filter_extension_class = '::Directory::Filter::Extension',
			my $file_name_class = '::Regular::Content::UTF8_wBOM');
	$package_resolver->provide_instance(
		my $passage_counter = '::Meta::Greenhouse::Passage_Counter');

# =--------------------------------------------------------------------------= #

sub is_indented
# /type method
# /effect "Tests whether the line is intended"
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A\h+(.*)\z});
}

sub is_section_name
# /type method
# /effect "Tests whether the line is a section name"
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	if (${$_[THIS]} =~ m{\A\[(.*)\]\z})
	{
		return($package_name_class->indirect_constructor($1));
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_association
# /type method
# /effect "Tests whether the line is an association"
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A(.+?)\h+=>\h+(.+)\z});
}

sub is_separated_values
# /type method
# /effect "Tests whether the line is a list of separated values"
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my @values = (${$_[THIS]} =~ m{(\H+)}sg);
	if (@values < 2)
	{
		return(IS_UNDEFINED);
	} else {
		return(\@values);
	}
}

sub is_directory
# /type method
# /effect "Tests whether the line is a directory name"
# //parameters
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (${$_[THIS]} =~ m{\A(.*)/\z}s)
	{
		return($directory_class->indirect_constructor($1));
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_directory_content
# /type method
# /effect "Tests whether the line is a directory listing"
# //parameters
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (${$_[THIS]} =~ m{/\A(.*)\*\.(\w+)\z}s)
	{
		next if ($passage_counter->is_second_pass($1));
#FIXME: untested
		return($filter_extension_class->indirect_constructor($1, $2));
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_file_name
# /type method
# /effect "Tests whether the line is a file name"
# //parameters
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (index(${$_[THIS]}, OS_FS_PATH_DELIMITER) > RDX_INDEX_NO_MATCH)
	{
		return($file_name_class->indirect_constructor(${$_[THIS]}));
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_ini_file
# /type method
# /effect "Tests whether the line is a .ini file name"
# //parameters
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (substr(${$_[THIS]}, -4, 4) eq '.ini')
	{
		return($file_name_class->indirect_constructor(${$_[THIS]}));
	} else {
		return(IS_UNDEFINED);
	}
}

#sub is_ini_package
## /type method
## /effect "Tests whether the line is an ini package"
## //parameters
## //returns
##	::Personality::Abstract::Instance +undefined
#{
#	if (${$_[THIS]} =~ m{\A\@(.*)\z}s)
#	{
#		return($package_name_class->indirect_constructor($1));
#	} else {
#		return(IS_UNDEFINED);
#	}
#}

sub is_package_anchor
# /type method
# /effect "Tests whether the line is a package anchor"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (${$_[THIS]} =~ m{\A(.*)::\z}s)
	{
		return($package_name_class->indirect_constructor($1));
	} else {
		return(IS_UNDEFINED);
	}
}

sub is_package_level_expander
# /type method
# /effect "Tests whether the line is a package hierarchy"
# //parameters
#	value
# //returns
#	?
{
	return($pkg_level_class->expands(${$_[THIS]}));
}

sub is_package_hierarchy_expander
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return($pkg_hierarchy_class->expands(${$_[THIS]}));
}

sub is_package_name
# /type method
# /effect "Tests whether the line is a package name"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Instance +undefined
{
	if (index(${$_[THIS]}, '::') > RDX_INDEX_NO_MATCH)
	{
		return($package_name_class->indirect_constructor(${$_[THIS]}));
	} else {
		return(IS_UNDEFINED);
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.189
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
