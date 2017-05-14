package Carrot::Individuality::Controlled::Localized_Messages::Monad
# /type class
# //parent_classes
#	::Individuality::Controlled::_Corporate::Monad
# //parameters
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
#	search_path  ::Modularity::Object::Inheritance::Directory_Tree::Name_Language
# /capability ""
{
	my ($inheritance, $search_path) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide_name_only(
		my $prototype_class = '[=project_pkg=]::Prototype');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $msg_directory = $meta_monad->package_file->dot_directory
		->entry('localized_messages');
	$msg_directory->consider_directory;

	$this->[ATR_MSG_DIRECTORY] = $msg_directory;
	$this->[ATR_PERL_ISA] = $meta_monad->parent_classes->perl_isa;
	$this->[ATR_PACKAGE_NAME] = $meta_monad->package_name;
	$this->[ATR_FILE_NAMES] = {};

	return;
}

my $find_message_file = \&find_message_file;
sub find_message_file
# /type method
# /effect ""
# //parameters
#	seen
#	msg_name
#	languages
# //returns
#	::Personality::Abstract::Array
{
	my ($this, $seen, $msg_name, $languages) = @ARGUMENTS;

	$seen //= $this->initially_seen;
	my $file_names = $this->[ATR_FILE_NAMES];
	if (exists($file_names->{$msg_name}))
	{
		return(IS_UNDEFINED) unless (defined($file_names->{$msg_name}));
		my $available_languages = $file_names->{$msg_name};
		foreach my $language (@$languages)
		{
			next unless (exists($available_languages->{$language}));
			return([$language, $available_languages->{$language}]);
		}
	}
	my ($language, $file_name) = $search_path->find_language_file(
		$this->[ATR_PACKAGE_NAME]->value,
		$msg_name,
		'.tpl',
		$languages,
		$this->[ATR_MSG_DIRECTORY]);
	if (defined($language))
	{
		$file_names->{$msg_name}{$language} = $file_name;
		return([$language, $file_name]);
	}

	return($inheritance->first_defined_skip_seen(
			$this->[ATR_PERL_ISA],
			$find_message_file,
			$seen,
			$msg_name,
			$languages));
}

sub provide_prototype
# /type method
# /effect ""
# //parameters
#	msg_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $msg_name (@ARGUMENTS)
	{
		$msg_name = $prototype_class->indirect_constructor(
			$this,
			$msg_name);
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.117
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"