package Carrot::Modularity::Package::File_Name::Combination
# /type class
# /instances singular
# /capability "Combination of files (of a package) across @MODULE_SEARCH_PATH"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/File_Name/Combination./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $array_class = '::Diversity::Attribute_Type::One_Anonymous::Array',
		my $file_name_class = '::Modularity::Package::File_Name',
		my $directory_name_class = '::Personality::Valued::File::Name::Type::Directory::Content');

# =--------------------------------------------------------------------------= #

sub list_level
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $pkg_file) = @ARGUMENTS;

	my $file_names = {};
	my $directory_name = $directory_name_class->constructor;

	foreach my $directory (@MODULE_SEARCH_PATH)
	{
		next unless (-d $directory);
		$directory_name->assign_value("$directory/$pkg_file");
		next unless ($directory_name->exists);

		my $listing = $directory_name->list;
		foreach my $candidate (@$listing)
		{
			next unless ($candidate =~ m{\A([\w_]+)\.pm\z});
			next if (exists($file_names->{$candidate}));
			$file_names->{$candidate} = IS_EXISTENT;
		}
	}
	return([map(
		$file_name_class->constructor("$pkg_file/$_"),
		keys($file_names))]);
}

sub list_level_qualified
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $pkg_file) = @ARGUMENTS;

	return([map(
		"$pkg_file/$_",
		@{$this->list_level($pkg_file)})]);
}

sub find_all
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $pkg_file) = @ARGUMENTS;

	my $file_names = $array_class->constructor;
	foreach my $directory (@MODULE_SEARCH_PATH)
	{
		my $file_name = "$directory/$pkg_file";
		next unless (-e $file_name);
		$file_names->append_value(
			$file_name_class->constructor($file_name));
	}
	return($file_names);
}

sub find_all_once
# /type method
# /effect ""
# //parameters
#	name
#	passage_counter
# //returns
#	?
{
	my ($this, $pkg_file, $passage_counter) = @ARGUMENTS;

	my $file_names = $array_class->constructor;
	foreach my $directory (@MODULE_SEARCH_PATH)
	{
		my $file_name = "$directory/$pkg_file";
		next unless (-e $file_name);
		next if ($passage_counter->is_second_pass($$file_name));
		$file_names->append_value(
			$file_name_class->constructor($file_name));
	}
	return($file_names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.101
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
