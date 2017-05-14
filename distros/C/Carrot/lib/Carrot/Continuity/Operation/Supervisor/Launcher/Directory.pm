package Carrot::Continuity::Operation::Supervisor::Launcher::Directory
# /type class
# /implements [=component_pkg=]::_Plugin_Prototype
# /attribute_type ::Many_Declared::Ordered
# /capability "Change the initial working directory."
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $directory_name_class = '::Personality::Valued::File::Name::Type::Directory');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	directory_name
# //returns
{
	my ($this, $directory_name) = @ARGUMENTS;

	$this->[ATR_DIRECTORY_NAME] = $directory_name_class
		->indirect_constructor($directory_name);

	return;
}

sub effect
# /type implementation
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_DIRECTORY_NAME]->change_fatally;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.110
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"