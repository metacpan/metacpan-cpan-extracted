package Carrot::Individuality::Singular::Execution::Eval_Analyzer::Constants
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub ECS_FILE() { "\x{1}file" }
sub ECS_SYNTAX() { "\x{1}syntax" }
sub ECS_DECLARATION() { "\x{1}declaration" }
sub ECS_UNKNOWN() { "\x{1}unknown" }

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

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
#	version 1.1.20
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
