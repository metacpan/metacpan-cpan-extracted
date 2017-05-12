use strict;
use Test::More 'no_plan';
use lib 't';
use CGI;
use CGI::Application::Framework;


# Set up query and app
my ($query, $app);
$query = new CGI;
$query->param('come_from_rm', 'login');
$query->param('current_rm',   'login');
$query->param('rm',           'testproj_start');


#######################################################################
# Fake that we've come from the login page with good parameters
$query->param('username',     'test');
$query->param('password',     'seekrit');

$ENV{'PATH_INFO'} = 'TestProj/testproj_1';

$app = CGI::Application::Framework->run_app(
    projects => 't/test_projects',
    app_params => {
        suppress_output => 1,
    },
    query => $query,
);


my $expected_output = <<'EOF';
--begin--
testproj_var1:my_value_one
testproj_var2:my_value_two
testproj_var3:my_value_three
--end--
EOF


ok($app->stash->{'Password_OK'},                       '[login, good parms] valid password');
ok($app->stash->{'User_OK'},                           '[login, good parms] valid user');

is($app->stash->{'Template_Output'}, $expected_output, 'template output good');





