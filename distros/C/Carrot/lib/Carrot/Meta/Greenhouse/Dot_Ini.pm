package Carrot::Meta::Greenhouse::Dot_Ini
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Processing of .ini files (global and package-specific)"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Dot_Ini./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $package_resolver = '::Modularity::Package::Resolver');

	$package_resolver->provide(
		my $package_name_class = '::Modularity::Package::Name',
		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM',
		my $directory_name_class = '::Personality::Valued::File::Name::Type::Directory',
		my $line_class = 'Carrot::Meta::Greenhouse::Dot_Ini::Line',
		my $cursor_class = '::Personality::Reflective::Iterate::Array::Cursor');

	$package_resolver->provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $application_directories = '::Meta::Greenhouse::Application_Directories',
		my $passage_counter = '::Meta::Greenhouse::Passage_Counter',
		my $search_path = '::Personality::Valued::File::Name::Type::Directory::Search_Path');


	require Carrot::Meta::Greenhouse::Site_Directories;
	my $site_directories = Carrot::Meta::Greenhouse::Site_Directories->constructor;

	my $candidates = $site_directories->subdirectories('configuration');
	foreach my $cfg_dir (@$candidates)
	{
		my $cfg_directory = $directory_name_class
			->indirect_constructor($cfg_dir);
#		$cfg_directory->canonify;
		$search_path->append_if_distinct($cfg_directory);
	}

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	subject
# //returns
{
	my ($this, $subject) = @ARGUMENTS;

	unless (defined($subject))
	{
		my $caller = [caller];
		$subject = $caller->[RDX_CALLER_PACKAGE];
	}
	$this->[ATR_SUBJECT] = $subject;

	return;
}

sub search_path
# /type function
# /effect "Returns the search path for .ini files"
# //parameters
# //returns
#	::Personality::Valued::File::Name::Type::Directory::Search_Path
{
	return($search_path);
}

sub find_configuration
# /type method
# /effect "Merges and processes lines from different sources"
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	$lines //= [];

	my $pkg_name = $this->[ATR_SUBJECT]->class_name;

	Carrot::Meta::Greenhouse::Dot_Ini::Startup::config_lines(
		$pkg_name,
		$lines);
	$this->site_ini_lines($pkg_name, $lines);
	$this->cut_lines($lines);

	eval {
		if ($this->[ATR_SUBJECT]->can('dot_ini_got_section'))
		{
			$this->process_lines($lines);
		} else {
			$this->process_section($lines);
		}
		return(IS_TRUE);
	} or $translated_errors->escalate(
		'finding_configuration',
		[$pkg_name],
		$EVAL_ERROR);

	return;
}

sub cut_lines
# /type method
# /effect "Removes lines up to cut marks"
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	foreach my $line (splice($lines))
	{
		if ($line eq '--8<--')
		{
			splice($lines);
		} else {
			push($lines, $line);
		}
	}
	return;
}

sub site_ini_files
# /type method
# /effect "Finds .ini files in the search path"
# //parameters
#	pkg_name        ::Personality::Abstract::Text
# //returns
#	?
{
	my ($this, $pkg_name) = @ARGUMENTS;

	return($search_path->find_all_once(
		["$pkg_name-$$compilation_name.ini",
		"$pkg_name.ini"],
	        $passage_counter));
}

sub site_ini_lines
# /type method
# /effect "Collects lines from the site ini files"
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	lines
# //returns
{
	my ($this, $pkg_name, $lines) = @ARGUMENTS;

	my $package_name = $package_name_class->indirect_constructor(
		$pkg_name);
	my $default_file = $package_name->dot_directory_actual
		->entry('default_settings.ini');
	if ($default_file->exists)
	{
		$default_file->consider_regular_content;
		push($lines, map(s{\A\h+}{}saar, @{$default_file->read_lines}));
	}

	my $file_names = $this->site_ini_files($pkg_name);
	foreach my $ini_file (@$file_names)
	{
		#FIXME: blindly added - might be wrong
		$ini_file->consider_regular_content;
		push($lines, @{$ini_file->read_lines});
	}

	return;
}

sub process_file
# /type method
# /effect "Processes lines of a file"
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	return if ($passage_counter->is_second_pass($file_name->value));
	$file_name->consider_regular_content;
	my $lines = $file_name->read_lines;

	eval {
		$this->process_lines($lines);
		return(IS_TRUE);
	} or $translated_errors->escalate(
		'named_file_operation',
		[$file_name],
		$EVAL_ERROR);

	if ($this->[ATR_SUBJECT]->can('dot_ini_completed_file'))
	{
		$this->[ATR_SUBJECT]->dot_ini_completed_file;
	}

	return;
}

sub process_lines
# /type method
# /effect "Processes given lines"
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	my $line = $line_class->indirect_constructor;
	my $cursor = $cursor_class->indirect_constructor($lines, $line);

	my $subject = $this->[ATR_SUBJECT];
	my $section = [];
	my $pkg_name = '';
	my $text;
	while ($cursor->advance)
	{
		$$line =~ s{\h+\z}{}saa; #FIXME: hardcoded
		next if ($line->is_comment_or_blank);

		if (($text) = $line->is_indented)
		{
			push($section, $text);

		} elsif (my $section_name = $line->is_section_name)
		{
			$subject->dot_ini_got_section(
				$pkg_name,
				$section);
			$section = [];
			$section_name->qualify('Carrot');
			$pkg_name = $section_name->value;

		} elsif (my $directory_content = $line->is_directory_content)
		{
			my $file_name = $file_name_class->indirect_constructor;
			my $cursor = $cursor_class->indirect_constructor(
				$directory_content->list_qualified,
				$file_name);
			while ($cursor->advance)
			{
				$this->process_file($file_name);
			}

		} elsif (my $ini_file = $line->is_ini_file)
		{
			$application_directories->resolve_placeholders($ini_file);
			$this->process_file($ini_file);

#		} elsif (my $ini_package = $line->is_ini_package)
#		{
#			my $file_name = $ini_package->dot_directory_actual
#				->entry('carrot_profile.ini');
#			$this->process_file($file_name);

		} else {
			$translated_errors->advocate(
				'invalid_line_format',
				[$$line]);
		}
	}
	$subject->dot_ini_got_section(
		$pkg_name,
		$section);

	splice($lines);
	return;
}

sub process_section
# /type method
# /effect "Process a given section"
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	my $line = $line_class->indirect_constructor;
	my $cursor = $cursor_class->indirect_constructor($lines, $line);

	my $prefix = 'Carrot';
	my $subject = $this->[ATR_SUBJECT];
	eval {
		while ($cursor->advance)
		{
			next if ($line->is_comment_or_blank);

			if (my ($name, $value) = $line->is_association)
			{
				$subject->dot_ini_got_association($name, $value);

			} elsif (my $values = $line->is_separated_values)
			{
				$subject->dot_ini_got_separated_values($values);

			} elsif (my $directory_name = $line->is_directory)
			{
				$application_directories->resolve_placeholders($directory_name);
				$directory_name->require_fatally;
				$subject->dot_ini_got_directory_name($directory_name);

			} elsif (my $file_name = $line->is_file_name)
			{
				$application_directories->resolve_placeholders($file_name);
				$file_name->require_fatally;
				if ($subject->can('dot_ini_got_file_name'))
				{
					$subject->dot_ini_got_file_name($$line);
				} else {
					$this->process_file($$line);
				}

			} elsif (my $package_anchor = $line->is_package_anchor)
			{
				$package_anchor->qualify('Carrot');
				$prefix = $package_anchor->value;
				next;

			} elsif (my $package_list = $line->is_package_level_expander)
			{
				$package_list->qualify($prefix);
				$this->dot_ini_got_package_list($package_list);

			} elsif (my $package_hierarchy = $line->is_package_hierarchy_expander)
			{
				$package_hierarchy->qualify($prefix);
				$this->dot_ini_got_package_list($package_hierarchy);

			} elsif (my $package_name = $line->is_package_name)
			{
				$package_name->qualify($prefix);
				$package_name->load;
				$subject->dot_ini_got_package_name($package_name);

			} else {
				$subject->dot_ini_got_something($$line);
			}
		}
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'line_error',
		[$$line],
		$EVAL_ERROR);
	return;
}

sub dot_ini_got_package_list
# /type method
# /effect "Process a package hierarchy from an .ini file"
# //parameters
#	package_hierarchy
# //returns
{
	my ($this, $pkg_hierarchy) = @ARGUMENTS;

	my $subject = $this->[ATR_SUBJECT];
	my $pkg_names = $pkg_hierarchy->expand;

	# _Corporate, _Role, etc. from expanding ::*
	@$pkg_names = grep (!$_->leading_underscore, @$pkg_names);


	if ($subject->can('dot_ini_got_package_names'))
	{
		$subject->dot_ini_got_package_list($pkg_names);
		return;
	}
	foreach my $pkg_name (@$pkg_names)
	{
		$subject->dot_ini_got_package_name($pkg_name);
	}
	return;
}

sub dot_ini_got_directory_name
# /type method
# /effect "Processes a directory name from an .ini file"
# //parameters
#	directory_name  ::Personality::Valued::File::Name::Type::Directory
# //returns
{
	my ($class, $directory_name) = @ARGUMENTS;

	$search_path->append_if_distinct($directory_name);

#FIXME: +.ini isn't processed for subsequently added directories
#	if (defined(my $plus_file = $directory_name->entry_if_exists('+-$$compilation_name.ini')))
#	{
#		$plus_file->consider_regular_content;
#		$dot_ini->process_file($plus_file);
#	}

	return;
}

# =--------------------------------------------------------------------------= #

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $startup_class = 'Carrot::Meta::Greenhouse::Dot_Ini::Startup');

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.480
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
