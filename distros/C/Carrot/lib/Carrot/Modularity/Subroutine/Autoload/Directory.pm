package Carrot::Modularity::Subroutine::Autoload::Directory
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Subroutine/Autoload//Directory./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $regular_content_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');
	$expressiveness->package_resolver->provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE');

	$named_re->provide(
		my $re_file_extension_pl = 'file_extension_pl');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_PACKAGE_NAME] = $meta_monad->package_name;

	my $content = $meta_monad->dot_directory->entry('autoload');
	$content->consider_directory_content;
	$content->create_fatally_if_missing;
	$this->[ATR_CONTENT] = $content;

	return;
}

sub store_unless_exists
# /type method
# /effect ""
# //parameters
#	sub_name
#	code
# //returns
{
	my ($this, $sub_name, $code) = @ARGUMENTS;

	my $file_name = $this->[ATR_CONTENT]->entry("$sub_name.pl");
	return if ($file_name->exists);

	$file_name->consider_regular_content;
	$file_name->overwrite_from($code);

	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $files = $this->[ATR_CONTENT]->list_by_extension('.pl');
	my $perl_code = join("\n",
		'#Automatically created on '
			. scalar(gmtime(time()))
			. ' GMT. Manual changes will get lost.',
		'package '
			. $this->[ATR_PACKAGE_NAME]->value
			. ';',
		'use strict;',
		'use warnings;',
		map("sub $_;", map(s{$re_file_extension_pl}{}ro, @$files)),
		'return(1);',
		'');

	my $index_name = $this->[ATR_CONTENT]->appended_value('.pl');
	my $index_file = $regular_content_class->indirect_constructor(
		$index_name);
	$index_file->overwrite_from($perl_code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.123
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
