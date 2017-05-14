package Carrot::Personality::Valued::Internet::Codec::URL
# /type package
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub decode
# /type function
# /effect ""
# //parameters
#	data
# //returns
{
	$_[SPX_DATA] =~ s{%([\da-fA-F]{2})}{chr(hex($1))}saaeg;
	return;
}

sub encode
# /type function
# /effect ""
# //parameters
#	data
# //returns
{
	$_[SPX_DATA] =~ s/(\W)/sprintf('%x', ord($1))/saaeg;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.30
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <win@carrot-programming.org>"
