use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
  my @requires = qw(
    Test::WWW::Mechanize::Catalyst
    DBD::SQLite
    Catalyst::Plugin::Session
    Catalyst::Plugin::Session::State::Cookie
  );

  foreach my $require ( @requires ) {
    eval "require $require"
      or plan skip_all => "$require is required for this test";
  }

  unless ( $Catalyst::Plugin::Session::VERSION >= 0.02 ) {
    plan skip_all =>
      "Catalyst::Plugin::Session >= 0.02 is required for this test";
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
            class      => 'Jifty::DBI',
            user_class => 'TestDB::User',
            use_userdata_from_session => 0,
          },
        },
      },
    },
  };
  $ENV{TESTAPP_PLUGINS} = [qw(
    Authentication
    Session
    Session::Store::Dummy
    Session::State::Cookie
  )];
}

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

{
  $mech->get_ok('http://localhost/db/setup');
  $mech->content_is('ok', 'setup database');
}

{
  $mech->get_ok('http://localhost/auth/user_login?username=joeuser&password=hackme');
  $mech->content_is('joeuser logged in', 'logged in');
}

{
  $mech->get_ok('http://localhost/auth/get_session_user');
  $mech->content_is('joeuser', 'user still logged in');
}

{
  $mech->get_ok('http://localhost/auth/user_logout');
  $mech->content_is('logged out', 'logged out');
}

{
  $mech->get_ok('http://localhost/auth/get_session_user');
  $mech->content_is('', 'session is deleted');
}

END { $mech && $mech->get('http://localhost/db/teardown'); }
