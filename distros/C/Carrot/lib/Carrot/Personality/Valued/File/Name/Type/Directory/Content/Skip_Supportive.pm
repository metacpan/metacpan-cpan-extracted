package Carrot::Personality::Valued::File::Name::Type::Directory::Content::Skip_Supportive
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory/Content/Skip_Supportive./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $array_class = '::Personality::Elemental::Array::Texts');

	my $supportive_indicators = $array_class->constructor(
		['.', '#', '~', '$', '%']);

# =--------------------------------------------------------------------------= #

sub list
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $names = [];
	foreach my $name (@{$this->SUPER::list})
	{
		next if ($supportive_indicators->contains(substr($name, 0, 1)));
		next if ($supportive_indicators->contains(substr($name, 0, -1)));
		push($names, $name);
	}
	return($names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
