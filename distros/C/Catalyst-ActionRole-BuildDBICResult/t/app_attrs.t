use strict;
use warnings;
use Test::More 0.89;
use HTTP::Request::Common qw/GET POST DELETE/;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp;

ok(TestApp->installdb, 'Setup Database');
ok(TestApp->deploy_dbfixtures, 'Fixtures Deployed');


use Catalyst::Test 'TestApp';

ok my $user100 = request(GET '/doesattrs/user_default/100')->content,
  'got user 100';

is $user100, 'user_default,john@shutterstock.com',
  'got expected values for user 100';

ok my $user999 = request(GET '/doesattrs/user_default/999')->content,
  'got user 100';

is $user999, 'user_default,notfound',
  'got expected values for user 999 (not found)';

done_testing;

