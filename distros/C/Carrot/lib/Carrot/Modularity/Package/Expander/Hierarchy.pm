package Carrot::Modularity::Package::Expander::Hierarchy
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Expander/Hierarchy./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $package_name_class = '::Modularity::Package::Name',
		my $skip_supportive_class = '::Personality::Valued::File::Name::Type::Directory::Content::Skip_Supportive',
		my $file_name_class = '::Personality::Valued::File::Name');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $english_re = '::Diversity::English::Regular_Expression',
		my $inc_search_path = '::Modularity::Package::File_Name::Combination',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $re_hierarchy = $english_re->compile('
		ON_START ( ANY_CHARACTER ANY_TIMES )
		PERL_PKG_DELIMITER  DOUBLE ASTERISK  ON_END',
		[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]);

# =--------------------------------------------------------------------------= #

sub expands
# /type class_method
# /effect ""
# //parameters
#	pkg_name
# //returns
#	?
{
	if ($_[SPX_CANDIDATE] =~ m{$re_hierarchy}o)
	{
		return($_[SPX_CLASS]->constructor($1));
	} else {
		return;
	}
}

sub find_level_with_files
# /type method
# /effect ""
# //parameters
#	directory_name  ::Personality::Valued::File::Name::Type::Directory
#	level
# //returns
{
	my ($this, $directory_name, $level) = @ARGUMENTS;

	die('#FIXME: deep recursion?') if (keys($level) > 100);

	my $base = $directory_name->value;

	#FIXME: unclear what the RE is for
	my $entries = [map(
		[($_ =~ s{\..+?\z}{}sr),
		$file_name_class->constructor("$base/$_")],
			@{$directory_name->list})];

	my $directories = [];
	my $pm_files = [];
	foreach my $entry (@$entries)
	{
		my ($key, $file_name) = @$entry;

		next if ($file_name->has_extension('')); # dot directory
		if ($file_name->is_type_directory)
		{
			push($directories, $key);
			next;
		}
		next unless ($file_name->is_type_regular);
		next unless ($file_name->has_extension('pm'));
		push($pm_files, $entry);
	}

	if (@$pm_files)
	{
		foreach my $entry (@$pm_files)
		{
			my ($key, $file_name) = @$entry;

			next if (exists($level->{$key}));
			$level->{$key} = $file_name;
		}
	} else {
		foreach my $entry (@$directories)
		{
			my ($key, $file_name) = @$entry;

			next if (exists($level->{$key}));
			my $base = {};
			$level->{$key} = $base;
			$file_name->class_change($skip_supportive_class);
			$this->find_level_with_files($file_name, $base);
		}
	}

	return;
}

sub flat_keys
# /type method
# /effect ""
# //parameters
#	result
#	base
#	level
# //returns
{
	my ($this, $result, $base, $level) = @ARGUMENTS;

	while (my ($key, $value) = each(%$level))
	{
		if (ref($value) eq 'HASH')
		{
			$this->flat_keys($result, "${base}::$key", $value);
		} else {
			push($result, "${base}::$key");
		}
	}

	return;
}

sub expand
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	$this->qualify('Carrot');
	# More than an assertion, because it's setup data
	unless ($this->is_valid)
	{
		$translated_errors->advocate(
			'invalid_package_name',
			[$$this]);
	}
	my $pkg_base = $this->base_name_logical;

	my $file_names = $inc_search_path->find_all($pkg_base);

	my $level = {};
	foreach my $file_name (@$file_names)
	{
		$file_name->class_change($skip_supportive_class);
		$this->find_level_with_files(
				$file_name,
				$level);
	}
	my $pkg_list = [];
	$this->flat_keys($pkg_list, $$this, $level);

	@$pkg_list = sort {$a cmp $b} @$pkg_list;
	my $package_list = [map(
		$package_name_class->constructor($_),
		@$pkg_list)];

	return($package_list);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.222
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
