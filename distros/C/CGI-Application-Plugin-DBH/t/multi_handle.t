use Test::More qw/no_plan/;
BEGIN { use_ok('CGI::Application::Plugin::DBH') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppMultiHandle;
my $t1_obj = TestAppMultiHandle->new();
my $t1_output = $t1_obj->run();

ok($t1_obj->dbh_default_name eq "__cgi_application_plugin_dbh", 
			"deafult handle name was preserved");

ok($t1_obj->param('orig_name1') eq "__cgi_application_plugin_dbh",
			"name stored for first dbh_default_name() is correct");
ok($t1_obj->param('orig_name2') eq "handle1",
			"name stored for second dbh_default_name() is correct");

use UNIVERSAL;

# Default handle should be unset
eval {$t1_obj->dbh};
ok($@ =~ /must call dbh_config/, 'dbh() method dies for default handle');

# We should have 4 named handles
ok($t1_obj->dbh('handle1')->isa('DBI::db'), 'dbh("handle1") method returns DBI handle');
ok($t1_obj->dbh('handle2')->isa('DBI::db'), 'dbh("handle2") method returns DBI handle');
ok($t1_obj->dbh('handle3')->isa('DBI::db'), 'dbh("handle3") method returns DBI handle');
ok($t1_obj->dbh('handle4')->isa('DBI::db'), 'dbh("handle4") method returns DBI handle');

# Handles 2 and 3 should be the same as 1
ok($t1_obj->dbh('handle2') == $t1_obj->dbh('handle1'), "handle2 is a copy of handle1");
ok($t1_obj->dbh('handle3') == $t1_obj->dbh('handle1'), "handle3 is a copy of handle1");

# Handle 4 should be different
ok($t1_obj->dbh('handle1') != $t1_obj->dbh('handle4'), "handle4 is not a copy of handle1");
ok($t1_obj->dbh('handle2') != $t1_obj->dbh('handle4'), "handle4 is not a copy of handle2");
ok($t1_obj->dbh('handle3') != $t1_obj->dbh('handle4'), "handle4 is not a copy of handle3");

