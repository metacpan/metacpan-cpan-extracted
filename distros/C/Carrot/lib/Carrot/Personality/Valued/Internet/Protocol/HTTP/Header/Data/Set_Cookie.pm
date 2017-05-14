package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::Set_Cookie
# /type class
# //parent_classes
#	::Personality::Recursive::Internet::Protocol::HTTP::Common::Header_Lines::_Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	
# =--------------------------------------------------------------------------= #

sub clear_key
# /type method
# /effect ""
# //parameters
#	key
# //returns
#	?
{
	${$_[THIS]} = $_[SPX_KEY].'=';
}

sub set_key
# /type method
# /effect ""
# //parameters
#	key
#	value
# //returns
#	?
{
	${$_[THIS]} = $_[SPX_KEY].'='.$_[SPX_VALUE];
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
