package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method::Constants
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


# =--------------------------------------------------------------------------= #

sub HTTP_REQUEST_METHOD_GET() { 'GET' }
sub HTTP_REQUEST_METHOD_HEAD() { 'HEAD' }
sub HTTP_REQUEST_METHOD_POST() { 'POST' }
sub HTTP_REQUEST_METHOD_PUT() { 'PUT' }

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return('HTTP_REQUEST_METHOD_', [qw(
		GET
		HEAD
		POST
		PUT
	)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.42
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
