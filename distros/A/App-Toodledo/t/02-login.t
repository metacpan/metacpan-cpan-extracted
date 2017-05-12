#!perl -T
use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;
use Test::Exception;
use Test::MockModule;

my $CLASS;
my $USERID   = 'username';
my $APPID    = 'appname';
my $PASSWORD = 'password';
my $APPTOKEN = 'token';
my $TOKEN    = 'savedtoken';

BEGIN { $CLASS = 'App::Toodledo'; use_ok $CLASS }

use App::Toodledo::Account;
my $todo = $CLASS->new( app_id => $APPID );

my $func;
my $got;
my $mock = Test::MockModule->new( $CLASS );
$mock->mock( _session_token_from_cache => sub { $TOKEN } );
$mock->mock( get => sub { $got = $_[1]; App::Toodledo::Account->new } );

throws_ok { $todo->login } qr/Validation/;

throws_ok { $todo->login( user_id => $USERID) } qr/Validation/;

lives_ok { $todo->login( user_id => $USERID, password => $PASSWORD,
		         app_token => $APPTOKEN ) };

is $got, 'account';
is $todo->user_id,   $USERID;
is $todo->app_id,    $APPID;
is $todo->app_token, $APPTOKEN;
