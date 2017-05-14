package Carrot::Personality::Valued::File::Name::Type::Directory::Filter::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory/Filter/_Corporate./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub list_qualified
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $names = [];
	my $base = $this->[ATR_NAME];
	foreach my $name (@{$this->list})
	{
		push($names, "$base/$name");
	}
	return($names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
