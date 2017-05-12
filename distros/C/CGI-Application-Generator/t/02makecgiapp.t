# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use CGI::Application::Generator;
ok(1); # If we made it this far, we're ok.

my $c = CGI::Application::Generator->new();

# Can we construct?
ok(ref($c) eq 'CGI::Application::Generator');

$c->package_name('WidgetBrowser');
$c->start_mode('show_form');      
$c->run_modes(qw/show_form do_search view_details/);
$c->use_modules(qw/DBI/);
$c->new_dbh_method('DBI->connect("DBD:mysql:WIDGETCORP")');
$c->tmpl_path('WidgetBrowser/');

# If we got his far, we can call methods
ok(1);

# Can we output?
my $app_module = $c->output_app_module();
ok($app_module);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

