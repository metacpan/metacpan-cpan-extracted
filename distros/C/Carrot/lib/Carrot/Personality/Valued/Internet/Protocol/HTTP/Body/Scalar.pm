package Carrot::Personality::Valued::Internet::Protocol::HTTP::Body::Scalar
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub is_file_handle
# /type method
# /effect "Distinguishes body types."
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(IS_FALSE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
