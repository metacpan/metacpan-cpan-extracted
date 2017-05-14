package Carrot::Productivity::Text::Placeholder::Template::File::Plain
# /type class
# /project_entry ::Productivity::Text::Placeholder
# //parent_classes
#	[=component_pkg=]::Generic
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->superseded(@ARGUMENTS);
	$this->[ATR_FILE_NAME] = IS_UNDEFINED;
	$this->[ATR_MTIME] = IS_UNDEFINED;

	return;
}

sub set_file
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$file_name->consider_regular_content;
	$this->[ATR_FILE_NAME] = $file_name;
	$this->[ATR_MTIME] = $file_name->status->modification_time;
	return;
}

sub modification_timestamp
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_MTIME]);
}

sub compile
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_FILE_NAME]->read_into(my $buffer);
	$this->superseded($buffer);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.70
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"