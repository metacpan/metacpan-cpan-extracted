use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
  my @requires = qw(
    DBD::SQLite
    Catalyst::Plugin::Authorization::Roles
  );

  foreach my $require ( @requires ) {
    eval "require $require"
      or plan skip_all => "$require is required for this test";
  }

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
            class       => 'Jifty::DBI',
            user_class  => 'TestDB::User',
            role_column => 'role_text',
          },
        },
      },
    },
  };
  $ENV{TESTAPP_PLUGINS} = [qw(
    Authentication
    Authorization::Roles
  )];
}

use Catalyst::Test 'TestApp';

{
  is get('/db/setup')
  => 'ok', 'setup database';
}

{
  is get('/auth/user_login?username=joeuser&password=hackme&detach=is_admin')
  => 'ok', 'user is an admin';
}

{
  is get('/auth/user_login?username=jayk&password=letmein&detach=is_admin')
  => 'not ok', 'user is not an admin';
}

{
  is get('/auth/user_login?username=nuffin&password=much&detach=is_admin_user')
  => 'ok', 'user is an admin and a user';
}

{
  is get('/auth/user_login?username=joeuser&password=hackme&detach=is_admin_user')
  => 'not ok', 'user is not an admin and a user';
}

END {
  get('/db/teardown');
}
