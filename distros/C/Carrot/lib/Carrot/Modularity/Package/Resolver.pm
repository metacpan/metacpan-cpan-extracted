package Carrot::Modularity::Package::Resolver
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Resolver./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $prefixed_list_class = '::Modularity::Package::Prefixed_List',
		my $package_name_class = '::Modularity::Package::Name');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $mappings = {};

# =--------------------------------------------------------------------------= #

sub _provide
# /type method
# /effect ""
# //parameters
#	caller
#	pkg_names  +multiple  ::Personality::Abstract::Text
# //returns
{
	my ($this, $caller) = splice(\@ARGUMENTS, 0, 2);

	my $calling_pkg = $caller->[RDX_CALLER_PACKAGE];
	my $anchor = 'Carrot';
	foreach my $requested (@ARGUMENTS)
	{
		my $pkg_name = $requested;
		next if ($prefixed_list_class->is_anchor_prefix(
			$pkg_name,
			$anchor,
			$calling_pkg));

		if (Scalar::Util::readonly($requested))
		{
			$translated_errors->advocate(
				'readonly_value',
				[$requested]);
		}

		my $package_name = $this->resolve($pkg_name, $anchor);
#		$package_name->load;
		$requested = $package_name;
	}
	return;
}

sub provide_name_only
# /type method
# /effect ""
# //parameters
#	pkg_names       ::Personality::Abstract::Text
# //returns
{
	shift(\@ARGUMENTS)->_provide([caller()], @ARGUMENTS);
	return;
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);
	my $caller = [caller()];

	$this->_provide($caller, @ARGUMENTS);
	foreach my $package_name (@ARGUMENTS)
	{
		next if (Scalar::Util::readonly($package_name));
		$package_name->load;
	}
	return;
}

sub provide_instance
# /type method
# /effect "Replaces the supplied string with an instance of that type."
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);
	my $caller = [caller()];

	$this->_provide($caller, @ARGUMENTS);
	foreach my $package_name (@ARGUMENTS)
	{
		next if (Scalar::Util::readonly($package_name));
		$package_name->load;
		$package_name = $package_name->indirect_constructor;
	}
	return;
}

sub resolve
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	prefix
# //returns
#	?
{
	my ($this, $pkg_name, $anchor) = @ARGUMENTS;

	if ($pkg_patterns->is_relative_package_name($anchor))
	{
		$anchor = 'Carrot'.$anchor;
	}
	if (exists($mappings->{$pkg_name}))
	{
		$pkg_name = $mappings->{$pkg_name};
	}

	my $package_name = $package_name_class->constructor($pkg_name);
	$package_name->qualify($anchor);
	unless ($package_name->is_valid)
	{
		$translated_errors->advocate(
			'invalid_package_name',
			[$package_name->value]);
	}

	return($package_name);
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

	$mappings->{$name} = $value;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.242
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
