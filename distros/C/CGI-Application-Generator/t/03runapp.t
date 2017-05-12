# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use CGI::Application::Generator;
ok(1); # If we made it this far, we're ok.

{
    my $c = CGI::Application::Generator->new();

    $c->package_name('WidgetBrowser');
    $c->start_mode('show_form');      
    $c->run_modes(qw/show_form do_search view_details/);
    $c->tmpl_path('WidgetBrowser/');

    my $app_module = $c->output_app_module();

    # Can we load this module?
    eval ( $app_module );
    ok(not($@));

    # Can we construct the resultant module?
    require CGI;
    my $app = WidgetBrowser->new( QUERY => CGI->new({rm => 'view_details'}) );
    ok(ref($app) eq 'WidgetBrowser');

    # Do we get the expected output?
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $cgiapp_output = $app->run();
    ok($cgiapp_output =~ /Content\-Type\:\ text\/html/);
    ok($cgiapp_output =~ /view\_details/);
}

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

