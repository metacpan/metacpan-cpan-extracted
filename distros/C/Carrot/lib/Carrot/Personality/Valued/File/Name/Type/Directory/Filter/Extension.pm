package Carrot::Personality::Valued::File::Name::Type::Directory::Filter::Extension
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory/Filter/Extension./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $directory_content_class = '::Personality::Valued::File::Name::Type::Directory::Content');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	directory
#	extension
# //returns
{
	my ($this, $directory, $extension) = @ARGUMENTS;

	$this->[ATR_NAME] = $directory_content_class->constructor($directory);
	$this->[ATR_EXTENSION] = $extension;

	return;
}

sub list
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $names = [];
	my $l = length($this->[ATR_EXTENSION]);
	foreach my $name (@{$this->[ATR_NAME]->list})
	{
		next if (substr($name, -$l) ne $this->[ATR_EXTENSION]);
		push($names, $name);
	}
	return($names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.50
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"