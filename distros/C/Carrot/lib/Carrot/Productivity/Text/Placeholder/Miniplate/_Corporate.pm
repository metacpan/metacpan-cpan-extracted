package Carrot::Productivity::Text::Placeholder::Miniplate::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	my ($this, $placeholder) = @ARGUMENTS;

	my $format = (($placeholder =~ s{@(.+)$}{}) ? $1 : undef);
	my $can = $this->can("syp_$placeholder");

	if (defined($can))
	{
		return([$can, [$this, $format]]);
	} else {
		return(IS_UNDEFINED);
	}
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
