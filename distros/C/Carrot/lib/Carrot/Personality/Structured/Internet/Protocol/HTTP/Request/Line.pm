package Carrot::Personality::Structured::Internet::Protocol::HTTP::Request::Line
# /type class
# /attribute_type ::Many_Declared::Ordered
# /class_anchor   ::Personality::Valued::Internet::Protocol::HTTP
# //attribute_construction
#	method    ::Request_Method +method
#	uri       ::URI +method
#	protocol  ::Protocol_Version +method
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub assign_value
# /type method
# /effect ""
# //parameters
#	method
#	uri
#	protocol
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_METHOD]->assign_value($_[SPX_METHOD]);
	$this->[ATR_URI]->assign_value($_[SPX_URI]);
	$this->[ATR_PROTOCOL]->assign_value($_[SPX_PROTOCOL]);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.77
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
