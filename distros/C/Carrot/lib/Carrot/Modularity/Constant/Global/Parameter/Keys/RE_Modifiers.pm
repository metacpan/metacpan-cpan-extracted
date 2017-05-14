package Carrot::Modularity::Constant::Global::Parameter::Keys::RE_Modifiers
# /type class
# /capability "Defines constants for English RE modifiers"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Parameter/Keys/RE_Modifiers./manual_modularity.pl');
	} #BEGIN

	sub RE_MOD_MULTIPLE_LINES() { 'm' }
	sub RE_MOD_SINGLE_LINE() { 's' }
	sub RE_MOD_IGNORE_CASE() { 'i' }
	sub RE_MOD_RELAXED_WHITESPACE() { 'x' }
	sub RE_MOD_PRESERVE_MATCH() { 'p' }
	sub RE_MOD_LOCALE() { 'l' }
	sub RE_MOD_UNICODE() { 'u' }
	sub RE_MOD_SAFE_UNICODE() { 'a' }
	sub RE_MOD_SAFER_UNICODE() { 'aa' }

	sub RE_OP_GLOBAL() { 'g' }
	sub RE_OP_KEEP_POSITION() { 'gc' }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array
{
	return('RE_', [qw(
		MOD_MULTIPLE_LINES
		MOD_SINGLE_LINE
		MOD_IGNORE_CASE
		MOD_RELAXED_WHITESPACE
		MOD_PRESERVE_MATCH
		MOD_LOCALE
		MOD_UNICODE
		MOD_SAFE_UNICODE
		MOD_SAFER_UNICODE
		OP_GLOBAL
		OP_KEEP_POSITION)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.27
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
