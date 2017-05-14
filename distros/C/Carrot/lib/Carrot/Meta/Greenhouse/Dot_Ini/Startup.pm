package Carrot::Meta::Greenhouse::Dot_Ini::Startup
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability "Initial processing of .ini files"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Dot_Ini/Startup./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $package_name_class = '::Modularity::Package::Name',
		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $package_resolver = '::Modularity::Package::Resolver');

	# magic place - must be defined before any call to Dot_Ini
	my $sections = {};
	my $dot_ini = Carrot::Meta::Greenhouse::Dot_Ini
		->constructor(__PACKAGE__);
	my $file_names = $dot_ini->site_ini_files('+');
	foreach my $file_name (@$file_names)
	{
		$dot_ini->process_file($file_name);
	}

# =--------------------------------------------------------------------------= #

sub dot_ini_got_section
# /type method
# /effect "Processes a section from an .ini file."
# //parameters
#	name
#	lines
# //returns
{
	my ($this, $name, $lines) = @ARGUMENTS;

	#NOTE: immediate effect for these package hierarchies
	if (($name =~ m{\ACarrot::Meta::Greenhouse::}saa)
	or ($name =~ m{\ACarrot::Modularity::Package::}saa))
	{
		$package_resolver->provide($name); # $name_class afterwards
		my $more_lines = [];
		my $class = $name->value;
		if ($class->can('dot_ini_got_section'))
		{
			$more_lines = $dot_ini->site_ini_files($class);
			@$more_lines = map($_->value, @$more_lines);

		} else {
			$dot_ini->site_ini_lines($class, $more_lines);
		}
		push($lines, @$more_lines);
		my $clone = $dot_ini->sibling_constructor($class);
		$clone->process_section($lines);
		return;
	}

	if (exists($sections->{$name}))
	{
		push($sections->{$name}, $lines);
	} else {
		$sections->{$name} = $lines;
	}
	return;
}

sub config_lines($$)
# /type function
# /effect "Appends previously stored lines from the section of the main .ini"
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	lines
# //returns
{
	my ($pkg_name, $lines) = @ARGUMENTS;

	if (exists($sections->{$pkg_name}))
	{
		push($lines, @{delete($sections->{$pkg_name})});
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.224
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
