use Test::Simple 'no_plan';
use strict;
use lib './lib';

use CGI::Application::Tutorial::Namegame;
$ENV{CGI_APP_RETURN_ONLY} = 1;


my $app = new CGI::Application::Tutorial::Namegame;
ok($app,'instanced');


$app->run;

