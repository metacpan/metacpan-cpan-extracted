package Carrot::Individuality::Controlled::Localized_Messages
# /type class
# //tabulators
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	MODULARITY {
		my $expressiveness = Carrot::modularity;
		$expressiveness->global_constants->add_plugins(
			'[=this_pkg=]::Constants');
	} #MODULARITY

	my $expressiveness = Carrot::individuality;
	my $package_resolver = $expressiveness->package_resolver;
	$package_resolver->provide(
		my $directory_name_class = '::Personality::Valued::File::Name::Type::Directory',
		my $array_class = '::Personality::Elemental::Array::Texts',
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini',
		'::Modularity::Object::Inheritance::',
			my $inheritance_class = '::ISA_Occupancy',
			my $name_language_class = '::Directory_Tree::Name_Language');

	$package_resolver->provide_name_only(
		'[=this_pkg=]::',
			my $monad_class = '::Monad',
			my $prototype_class = '::Prototype');

	$package_resolver->provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $search_path = '::Personality::Valued::File::Name::Type::Directory::Search_Path',
		my $site_directories = '::Meta::Greenhouse::Site_Directories');

	my $candidates = $site_directories->subdirectories('localized_messages');
	foreach my $directory (@$candidates)
	{
		$search_path->append_if_distinct(
			$directory_name_class->indirect_constructor(
				$directory));
	}

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
	$this->[ATR_SEARCH_PATH] = $search_path;
	$this->[ATR_UNI_CLASSES] = $array_class->indirect_constructor;
	$this->[ATR_OPERATOR_LANGUAGES] = $array_class->indirect_constructor;
	$this->[ATR_FALLBACK_LANGUAGE] = 'en_US'; #FIXME: hardcoded values

	my $inheritance = $inheritance_class->indirect_constructor(
		$this->[ATR_MONADS],
		$this->[ATR_UNI_CLASSES]);

	my $name_language = $name_language_class->indirect_constructor(
		$this->[ATR_SEARCH_PATH],
		$this->[ATR_FALLBACK_LANGUAGE],
		$this->[ATR_OPERATOR_LANGUAGES]);

	$monad_class->load($inheritance, $name_language);

	$prototype_class->load(
		$this->[ATR_OPERATOR_LANGUAGES]);

	return;
}

# sub fallback_language
# # method (<this>) public
# {
# 	return($_[THIS][ATR_FALLBACK_LANGUAGE]);
# }
#
# sub operator_languages
# # method (<this>) public
# {
# 	return($_[THIS][ATR_OPERATOR_LANGUAGES]);
# }

sub add_universal
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->manual_individuality($meta_monad);
	$this->dot_ini_got_package_name($meta_monad->package_name);
	return;
}

sub final_monad_setup
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$package_resolver->provide(
		my $universal_class =  '[=this_pkg=]::Universal');

	$this->[ATR_UNI_CLASSES]->append_if_distinct(
		$universal_class->value);

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	$this->[ATR_OPERATOR_LANGUAGES]->append_if_distinct(
		$this->[ATR_FALLBACK_LANGUAGE]);
	return;
}

sub dot_ini_got_association
# /type method
# /effect "Processes an association from an .ini file."
# //parameters
#	name
#	value
# //returns
{
	my ($this, $name, $value) = @ARGUMENTS;

	if ($name eq 'operator_languages')
	{
		@{$this->[ATR_OPERATOR_LANGUAGES]} =
			split(qr{,\h*}, $value, PKY_SPLIT_RETURN_FULL_TRAIL);

	} elsif ($name eq 'fallback_language')
	{
		$this->[ATR_FALLBACK_LANGUAGE] = $value;
	}

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

	$this->[ATR_SEARCH_PATH]->append_if_distinct($directory_name);

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

	$package_name->load;
	$this->[ATR_UNI_CLASSES]->append_if_distinct($package_name->value);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.271
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
