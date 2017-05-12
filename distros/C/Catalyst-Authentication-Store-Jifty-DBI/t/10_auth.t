use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
  eval { require DBD::SQLite; }
    or plan skip_all => "DBD::SQLite is required for this test";

  plan 'no_plan';

  $ENV{TESTAPP_DB_FILE} ||= "$FindBin::Bin/auth.db";
  $ENV{TESTAPP_CONFIG} = {
    name => 'TestApp',
    authentication => {
      default_realm => 'users',
      realms => {
        users => {
          credential => {
            class => 'Password',
            password_field => 'password',
            password_type  => 'clear',
          },
          store => {
            class => 'Jifty::DBI',
            user_class => 'TestDB::User',
          },
        },
      },
    },
  };
  $ENV{TESTAPP_PLUGINS} = [qw( Authentication )];
}

use Catalyst::Test 'TestApp';

{
  is get('/db/setup')
  => 'ok', 'setup database';
}

{
  is get('/auth/user_login?username=joeuser&password=hackme')
  => 'joeuser logged in', 'user logged in';
}

{
  is get('/auth/user_login?username=foo&password=bar')
  => 'not logged in', 'user not logged in';
}

{
  is get('/auth/user_login?username=spammer&password=broken')
  => 'spammer logged in', 'status check - disabled user logged in';
}

{
  is get('/auth/notdisabled_login?username=spammer&password=broken')
  => 'not logged in', 'status check - disabled user not logged in';
}

{
  is get('/auth/user_logout')
  => 'logged out', 'user logged out';
}

{
  is get('/auth/limit_args_login?email=nada%40mucho.net&password=much')
  => 'nuffin logged in', 'limit_args based logged in';
}

{
  is get('/auth/collection_login?email=j%40cpants.org&password=letmein')
  => 'jayk logged in', 'collection based logged in';
}

END {
  get('/db/teardown');
}
