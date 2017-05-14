package Carrot::Modularity::Object::Inheritance::Directory_Tree::Name_Language
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Inheritance/Directory_Tree/Name_Language./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	directories
#	fallback_language
#	operator_languages
# //returns
{
	my ($this, $directories, $fallback_language, $operator_languages) = @ARGUMENTS;

	$this->[ATR_DIRECTORIES] = $directories;
	$this->[ATR_FALLBACK_LANGUAGE] = $fallback_language;
	$this->[ATR_OPERATOR_LANGUAGES] = $operator_languages;

	return;
}

sub find_language_file
# /type method
# /effect ""
# //parameters
#	package_name    ::Modularity::Package::Name
#	msg_name
#	extension
#	languages
#	package_directory
# //returns
#	?
{
	my ($this, $pkg_name, $msg_name, $extension, $languages, $package_directory) = @ARGUMENTS;

	$languages //= $this->[ATR_OPERATOR_LANGUAGES];

	foreach my $language (@$languages)
	{
		my $message_file = "$msg_name/$language$extension";
		my $package_messages = "$pkg_name/$message_file";

		foreach my $directory (@{$this->[ATR_DIRECTORIES]})
		{
			my $file_name = $directory->entry_if_exists($package_messages);
			next unless (defined($file_name));
			return($language, $file_name);
		}

		my $file_name = $package_directory->entry_if_exists($message_file);
		if (defined($file_name))
		{
			return($language, $file_name);
		}
	}

	if ($languages == $this->[ATR_OPERATOR_LANGUAGES])
	{
		return(IS_UNDEFINED, IS_UNDEFINED);
	}
	if (grep(($this->[ATR_FALLBACK_LANGUAGE] eq $_), @$languages) > 0)
	{
		return(IS_UNDEFINED, IS_UNDEFINED);
	}
	return($this->find_language_file(
		       $pkg_name,
		       $msg_name,
		       $extension,
		       [$this->[ATR_FALLBACK_LANGUAGE]],
		       $package_directory));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.78
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"