package Carrot::Productivity::Text::Placeholder::Templague::Directory_Listing
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $placeholder_class = '::Productivity::Text::Placeholder');
	$expressiveness->class_names->provide(
		my $directory_class = '::Personality::Valued::File::Name::Type::Directory::Content');
		my $template_class = '[=project_pkg=]::Template::Generic');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	format
# //returns
{
	my ($this) = @ARGUMENTS;

	my $template = $template_class->indirect_constructor(
		$this->[ATR_COUNTER] = '::Miniplate::Counter',
		$this->[ATR_FILE_AGGREGATE] = '::Miniplate::Aggregator');

	$this->[ATR_FILE_AGGREGATE]->add_miniplate(
		my $file_name = '::Miniplate::OS::Unix::File::Name',
		my $file_properties = '::Miniplate::OS::Unix::File::Properties');

	$template->compile($_[SPX_FORMAT]);
	$this->[ATR_TEMPLATE] = $template;

	return;
}

sub generate
# /type method
# /effect ""
# //parameters
#	directory
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $file_names = $directory_class->indirect_constructor(
		$_[SPX_DIRECTORY])->list;

	my $rows = [];
	foreach my $file_name (@$file_names)
	{

		$this->[ATR_COUNTER]->increase;
		$this->[ATR_FILE_AGGREGATE]->set_subject($file_name);

		my $text = $this->[ATR_TEMPLATE]->execute;
		push($rows, $text);
	}
	return($rows);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"