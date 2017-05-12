#!perl -T
# This test suite has been contributed by Michael Graham
# who also suggested the is_auto_runmode function


#########################


use Test::More tests => 13;
BEGIN { use_ok('CGI::Application::Plugin::AutoRunmode') };

#########################

# Test CGI::App class
{
    package MyTestApp;
    use base 'CGI::Application';
    use CGI::Application::Plugin::AutoRunmode
        qw [ cgiapp_prerun ];

     sub mode1 : Runmode {
        'mode1';
     }

     sub not_a_runmode{
        'not a runmode';
     }

     sub start_mode1 : StartRunmode {
        'start_mode1';
     }
}

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=mode1';

use CGI;
my $q = new CGI;
{
    my $testname = "call with no runmode";
    my $app = new MyTestApp(QUERY=>$q);
    my $t = $app->run;
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'mode1'),         "[$testname] mode1");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'not_a_runmode'), "[$testname] not_a_runode");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'non_existing'),  "[$testname] non_existing");
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'start_mode1'),   "[$testname] start_mode1");
}

{
    my $testname = "call with mode1";
    $q->param(rm => 'mode1');
    my $app = new MyTestApp(QUERY=>$q);
    my $t = $app->run;
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'mode1'),         "[$testname] mode1");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'not_a_runmode'), "[$testname] not_a_runode");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'non_existing'),  "[$testname] non_existing");
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'start_mode1'),   "[$testname] start_mode1");
}

{
    my $testname = "start_mode1";
    $q->param(rm => 'start_mode1');
    my $app = new MyTestApp(QUERY=>$q);
    my $t = $app->run;
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'mode1'),         "[$testname] mode1");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'not_a_runmode'), "[$testname] not_a_runode");
    ok(!CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'non_existing'),  "[$testname] non_existing");
    ok( CGI::Application::Plugin::AutoRunmode::is_auto_runmode($app, 'start_mode1'),   "[$testname] start_mode1");
}

1;