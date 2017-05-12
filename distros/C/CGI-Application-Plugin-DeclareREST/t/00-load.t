use strict;
use warnings;

use Test::More;

BEGIN {
	use base 'CGI::Application';
	use_ok('CGI::Application::Plugin::DeclareREST') or BAIL_OUT "Can't use CGI::Application::Plugin::DeclareREST";
}

done_testing();