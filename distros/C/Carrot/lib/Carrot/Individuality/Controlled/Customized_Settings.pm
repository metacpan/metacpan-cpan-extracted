package Carrot::Individuality::Controlled::Customized_Settings
# /type class
# //tabulators
#	::Definition
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name');

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini',
		my $inheritance_class = '::Modularity::Object::Inheritance::ISA_Occupancy',
		'::Personality::',
			my $cursor_class = '::Reflective::Iterate::Array::Cursor',
			my $search_path_class = '::Valued::File::Name::Type::Directory::Search_Path',
		my $line_class = '[=this_pkg=]::Dot_Cfg::Line',
	);
	$expressiveness->package_resolver->provide_name_only(
		my $monad_class = '[=this_pkg=]::Monad');
	$expressiveness->package_resolver->provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MONADS] = {};
	$this->[ATR_MONAD_CLASS] = $monad_class;

	$this->[ATR_SEARCH_PATH] = $search_path_class->indirect_constructor;
	$this->[ATR_CONFIG] = {};
	$this->[ATR_INHERITANCE] =
		$inheritance_class->indirect_constructor(
			$this->[ATR_MONADS]);

	$monad_class->load($this->[ATR_INHERITANCE]);

	my $search_path = Carrot::Meta::Greenhouse::Dot_Ini::search_path;
	foreach my $directory_name (@$search_path)
	{
		$this->dot_ini_got_directory_name($directory_name);
	}

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	return;
}

sub dot_ini_got_directory_name
# /type method
# /effect "Processes a directory name from an .ini file."
# //parameters
#	directory_name  ::Personality::Valued::File::Name::Type::Directory
# //returns
{
	my ($this, $directory_name) = @ARGUMENTS;

	unless ($this->[ATR_SEARCH_PATH]->append_if_distinct($directory_name))
	{
		return;
	}

	my $file_name = $directory_name->entry('+.cfg');
	if ($file_name->exists)
	{
		$file_name->consider_regular_content;
		$this->add_any_config($file_name);
	}
	return;
}

sub add_any_config
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	my $line = $line_class->indirect_constructor;
	my $cursor = $cursor_class->indirect_constructor(
		$file_name->read_lines,
		$line);
	my $section = [];
	my $name = IS_UNDEFINED;
	my $config = $this->[ATR_CONFIG];
	while ($cursor->advance)
	{
		if ($line->is_comment_or_empty)
		{
			next;

		} elsif (my ($text) = $line->is_section)
		{
			if (defined($name))
			{
				$config->{$name} = $section;
				$section = [];
			}
			if ($pkg_patterns->is_relative_package_name($text))
			{
				$text = 'Carrot'.$text;
			}
			$name = $text;

		} else {
			push($section, $$line);

		}
	}
	if (defined($name))
	{
		$config->{$name} = $section;
	}
	return;
}

sub _manual_principle
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
#	?
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $monad = $monad_class->indirect_constructor(
		$meta_monad);

	my $pkg_name = $meta_monad->package_name->value;
	if (exists($this->[ATR_CONFIG]{$pkg_name}))
	{
		$monad->customize_by_arrayref(
			delete($this->[ATR_CONFIG]{$pkg_name}));
	}
	my $more_cfg_files = $this->[ATR_SEARCH_PATH]->find_all(
		["$pkg_name-$$compilation_name.cfg",
		"$pkg_name.cfg"]);
	$more_cfg_files->run_on_all($monad, 'customize_by_file');

	return($monad);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.218
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
