use FindBin '$Bin';
use lib "$Bin/../lib";

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
	use_ok( 'CGI::Application' );
	use_ok( 'CGI::Application::Plugin::ValidateQuery', ':types' );
	use_ok( 'CGI::Application::Plugin::ValidateQuery', ':all' );
	use_ok( 'CGI::Application::Plugin::ValidateQuery', 
        qw/:types validate_query/ 
    );
}

diag( "Testing CGI::Application::Plugin::ValidateQuery $CGI::Application::Plugin::ValidateQuery::VERSION, Perl $], $^X" );
