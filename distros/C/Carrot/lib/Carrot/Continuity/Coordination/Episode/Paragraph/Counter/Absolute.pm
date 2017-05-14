package Carrot::Continuity::Coordination::Episode::Paragraph::Counter::Absolute
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	${$_[THIS]} = 0;
	return;
}

sub reset
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	${$_[THIS]} = 0;
	return;
}

sub increment
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	${$_[THIS]} += 1;
	return;
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