package Carrot::Modularity::Constant::Global::Result_Indices::Caller
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Result_Indices/Caller./manual_modularity.pl');
	} #BEGIN

	sub RDX_CALLER_PACKAGE() { 0 };
	sub RDX_CALLER_FILE() { 1 };
	sub RDX_CALLER_LINE() { 2 };
	sub RDX_CALLER_SUB_NAME() { 3 }
	sub RDX_CALLER_HAS_ARGS() { 4 }
	sub RDX_CALLER_WANTS_ARRAY() { 5 }
	sub RDX_CALLER_EVAL_TEXT() { 6 }
	sub RDX_CALLER_IS_REQUIRE() { 7 }
	sub RDX_CALLER_HINTS() { 8 }
	sub RDX_CALLER_BIT_MASK() { 9 }
	sub RDX_CALLER_HINT_HASH() { 10 }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('RDX_CALLER_', [qw(
		PACKAGE
		FILE
		LINE
		SUB_NAME
		HAS_ARGS
		WANTS_ARRAY
		EVAL_TEXT
		IS_REQUIRE
		HINTS
		BIT_MASK
		HINT_HASH)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.43
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
