package Carrot::Meta::Greenhouse::Dot_Ini::Plugin_Like
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Base class for monad providers working with plugins"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Dot_Ini/Plugin_Like./manual_modularity.pl');
	} #BEGIN

	my $dot_ini_class = 'Carrot::Meta::Greenhouse::Dot_Ini';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_PLUGINS] = [];
	$this->[ATR_PLUGIN_NAMES] = {};

	my $default = [$this->default_plugin_autoload];
	my $dot_ini = $dot_ini_class->constructor($this);
	$dot_ini->find_configuration($default);

	return;
}

sub default_plugin_autoload
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	return(Scalar::Util::blessed($_[THIS]).'::**');
}

sub _add_plugin
# /type method
# /effect ""
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	$package_name->load;
	my $pkg_name = $package_name->value;
	return if (exists($this->[ATR_PLUGIN_NAMES]{$pkg_name}));

	push(@{$this->[ATR_PLUGINS]}, $package_name->indirect_constructor);
	$this->[ATR_PLUGIN_NAMES]{$pkg_name} = IS_EXISTENT;

	return;
}

sub dot_ini_got_package_name
# /type method
# /effect "Processes a package name from na .ini file."
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	$this->add_plugin($package_name);
	return;
}

sub dot_ini_got_package_list
# /type method
# /effect ""
# //parameters
#	pkg_names       ::Personality::Abstract::Text
# //returns
{
	my ($this, $pkg_names) = @ARGUMENTS;

	foreach my $pkg_name (@$pkg_names)
	{
		$this->add_plugin($pkg_name);
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.343
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"