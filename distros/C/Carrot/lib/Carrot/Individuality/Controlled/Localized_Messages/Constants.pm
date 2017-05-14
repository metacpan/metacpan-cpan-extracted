package Carrot::Individuality::Controlled::Localized_Messages::Constants
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub HKY_DEX_LINE_COUNT() { "\x{2}\@" }
sub HKY_DEX_LANGUAGE() { "\x{2}!" }
sub HKY_DEX_CALLER_OFFSET() { "\x{2}#" }
sub HKY_DEX_BACKTRACK() { "\x{2}?" }

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return('HKY_DEX_', [qw(
		LINE_COUNT
		LANGUAGE
		CALLER_OFFSET
		BACKTRACK)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.44
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
