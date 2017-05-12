#!/usr/bin/perl
use Test::More;
use lib 't/lib';

eval "use CGI::Application::Plugin::Session";
plan skip_all => "CGI::Application::Plugin::Session required for this test"
  if $@;

eval "use Digest::MD5";
plan skip_all => "Digest::MD5 required for this test"
  if $@;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test"
  if $@;

plan tests => 3;

use strict;
use warnings;

use CGI ();
use TestAppAuthMD5;
use TestUsers;
use File::Path;

mkpath(['t/db']);
TestUsers->setuptables;

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $query =
  CGI->new(
  { auth_username => 'usermd5', auth_password => 'testpassword', rm => 'two' }
  );

my $cgiapp  = TestAppAuthMD5->new( QUERY => $query );
my $results = $cgiapp->run;

ok( $cgiapp->authen->is_authenticated, 'successful login MD5' );
is( $cgiapp->authen->username, 'usermd5', 'successful login MD5 - username set' );
is( $cgiapp->authen->login_attempts,
  0, "successful login MD5 - failed login count" );

END {
  rmtree(['t/db']);
}
