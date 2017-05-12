use Test::More;
use Test::MockObject;
use strict;
use warnings;

# Create our app instance that uses the plugin
my $app = TestAppExistingDBH->new();

# Mock a DBI object.
my $mock_dbh = Test::MockObject->new;
   $mock_dbh->set_isa('DBI::db');
   $mock_dbh->set_true('ping');

# Test using the existing handle.
$app->dbh_config($mock_dbh);
isa_ok($app->dbh,'DBI::db','dbh() method returns DBI handle when using existing handle');

done_testing();

package TestAppExistingDBH;
use parent 'CGI::Application';
use CGI::Application::Plugin::DBH qw(dbh_config dbh);
