package Carrot::Personality::Valued::Internet::Protocol::HTTP::Protocol_Version::Constants
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


# =--------------------------------------------------------------------------= #

sub HTTP_VERSION_1DOT0() { 'HTTP/1.0' }
sub HTTP_VERSION_1DOT1() { 'HTTP/1.1' }

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return('HTTP_VERSION_', [qw(
		1DOT0
		1DOT1
	)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
