use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use Cwd;
ok(1);

use CGI::Application::HelpMan;
$ENV{CGI_APP_RETURN_ONLY} = 1;


my $t = new CGI::Application::HelpMan;
ok($t,'instanced');
ok($t->run);

ok(1);



