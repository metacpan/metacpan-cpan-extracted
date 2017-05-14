package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::_Scalar
# /type class
# //parent_classes
#	::Personality::Elemental::Scalar::Textual
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub sort_category
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(PERL_FILE_LOADED);
}

sub has_data
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(defined(${$_[THIS]}));
}

sub parse
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	${$_[THIS]} = $_[SPX_VALUE];
}

sub add
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	${$_[THIS]} .= "; ".$_[SPX_VALUE];
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.39
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
