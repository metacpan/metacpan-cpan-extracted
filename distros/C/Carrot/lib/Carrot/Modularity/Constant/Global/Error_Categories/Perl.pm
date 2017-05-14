package Carrot::Modularity::Constant::Global::Error_Categories::Perl
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Error_Categories/Perl./manual_modularity.pl');
	} #BEGIN

	sub ECS_FILE() { "\x{1}file" }
	sub ECS_SYNTAX() { "\x{1}syntax" }
	sub ECS_DECLARATION() { "\x{1}declaration" }
	sub ECS_UNKNOWN() { "\x{1}unknown" }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('ECS_', [qw(
		FILE
		SYNTAX
		DECLARATION
		UNKNOWN)]);
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
