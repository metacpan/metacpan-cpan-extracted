package Carrot::Modularity::Package::File_Name
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/File_Name./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $directory_class = '::Personality::Valued::File::Name::Type::Directory',
		my $package_name_class = '::Modularity::Package::Name');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns');

# =--------------------------------------------------------------------------= #

sub is_supportive
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{/_}s);
}

sub dot_directory
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($directory_class->constructor(
	       $pkg_patterns->dot_directory_from_file(
		       ${$_[THIS]})));
}

sub as_package_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my $pkg_name = (${$_[THIS]} =~ s{/}{::}saagr);
	# NOTE: works only one package files, not on (e.g. unit test) scripts
	$pkg_name =~ s{\..*\z}{}saa;
	return($package_name_class->constructor($pkg_name));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.119
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
