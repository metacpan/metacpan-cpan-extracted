#!/usr/bin/perl
use Test::More;
use lib 't/lib';

eval "use CGI::Application::Plugin::Session";
plan skip_all => "CGI::Application::Plugin::Session required for this test"
  if $@;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test"
  if $@;

plan tests => 8;

use strict;
use warnings;

use CGI ();
use TestAppAuthenticate;
use TestUsers;
use File::Path;

mkpath(['t/db']);
TestUsers->setuptables;

$ENV{CGI_APP_RETURN_ONLY} = 1;

# Missing Credentials
my $query =
  CGI->new( { auth_username => 'user1', rm => 'two' } );

my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

my $results = $cgiapp->run;

ok(!$cgiapp->authen->is_authenticated,'missing credentials - login failure');
is( $cgiapp->authen->username, undef, 'missing credentials - username not set' );

# Successful Login
$query =
 CGI->new( { auth_username => 'user1', auth_password => '123', rm => 'two' } );

$cgiapp = TestAppAuthenticate->new( QUERY => $query );
$results = $cgiapp->run;

ok($cgiapp->authen->is_authenticated,'successful login');
is( $cgiapp->authen->username, 'user1', 'successful login - username set' );
is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );

# Bad user or password
$query =
 CGI->new( { auth_username => 'user2', auth_password => '123', rm => 'two' } );
$cgiapp = TestAppAuthenticate->new( QUERY => $query );
$results = $cgiapp->run;

ok(!$cgiapp->authen->is_authenticated,'login failure');
is( $cgiapp->authen->username, undef, "login failure - username not set" );
is( $cgiapp->authen->login_attempts, 1, "login failure - failed login count" );

END {
  rmtree(['t/db']);
}
