#! perl

use Test::More tests => 2;
use Dancer::Test;

use Dancer ':tests';
use Dancer::Plugin::Nitesi;

my $ret;

set plugins => {Nitesi =>
                {Account =>
                 {Provider => 'Test',
                 users => {nitesi =>
                           {password => 'nevairbe',
                           }}}}};

# login test with valid password
$ret = account->login(username => 'nitesi', password => 'nevairbe');

ok ($ret, "Login test.")
    || diag "Failed to login.";

# login test with invalid password
$ret = account->login(username => 'nitesi', password => 'secret');

ok (! $ret, "Login test with invalid password.")
    || diag "Successful login with invalid password.";
