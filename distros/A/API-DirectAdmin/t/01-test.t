#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw( ./lib );


use Data::Dumper;

our $ONLINE;

BEGIN {
    #$ENV{auth_user}   = 'restest';
    #$ENV{auth_passwd} = '123';
    #$ENV{host}        = '192.168.123.1';
    $ONLINE = $ENV{auth_user} && $ENV{auth_passwd} && $ENV{host};
}

my $manipulate_user = 'zsezse';

use Test::More tests => $ONLINE ? 34 : 34;
my %connection_params = (
    host	=> $ENV{host} || '127.0.0.1',
    auth_user	=> $ENV{auth_user} || 'login',
    auth_passwd => $ENV{auth_passwd} || 'passwd',
);

ok(1, 'Test OK');
use_ok('API::DirectAdmin');

my $da = API::DirectAdmin->new(%connection_params);

my $func = 'filter_hash';
is_deeply( $da->filter_hash( {  }, [ ]), {}, $func );
is_deeply( $da->filter_hash( { aaa => 555, bbb => 111 }, [ 'aaa' ]), { aaa => 555 }, $func );
is_deeply( $da->filter_hash( { aaa => 555, bbb => 111 }, [ ]), { }, $func );
is_deeply( $da->filter_hash( { }, [ 'aaa' ]), { }, $func );

$func = 'mk_query_string';
is( $da->mk_query_string( {  }  ), '', $func );
is( $da->mk_query_string( ''    ), '', $func );
is( $da->mk_query_string( undef ), '', $func );
is( $da->mk_query_string( { aaa => 111, bbb => 222 } ), 'aaa=111&bbb=222', $func );
is( $da->mk_query_string( { bbb => 222, aaa => 111 } ), 'aaa=111&bbb=222', $func );
is( $da->mk_query_string( [ ] ), '', $func );
is( $da->mk_query_string( { dddd => 'dfdf' } ), 'dddd=dfdf', $func );

$func = 'mk_full_query_string';
is( $da->mk_full_query_string( { command => 'CMD' } ), 
    'https://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?',
    $func
);

is( $da->mk_full_query_string( { command => 'CMD', allow_https => 0 } ), 
    'http://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?',
    $func
);

is( $da->mk_full_query_string( {
	command => 'CMD',
        param1  => 'val1',
        param2  => 'val2',
    } ), 
    'https://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?param1=val1&param2=val2',
    $func
);

is( $da->mk_full_query_string( {
        param1      => 'val1',
        param2      => 'val2',
        command     => 'CMD',
	    allow_https => 0, 
    } ), 
    'http://'.$connection_params{auth_user}.':'.$connection_params{auth_passwd}.'@'.$connection_params{host}.':2222/CMD?param1=val1&param2=val2',
    $func
);

# IP

use_ok('API::DirectAdmin::Ip');

$da->{fake_answer} = ! $ONLINE ? { list => ['127.0.0.1'], error => 0 } : undef;

my $ip_list = $da->ip->list();

my $main_shared_ip = $ip_list->[0];
ok($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list, 'API::DirectAdmin::Ip::list');

my %answer = (
    text    => "User $manipulate_user created",
    error   => 0,
    details => 'Unix User created successfully
Users System Quotas set
Users data directory created successfully
Domains directory created successfully
Domains directory created successfully in users home
Domain Created Successfully');
$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

# User

use_ok('API::DirectAdmin::User');

my $result = $da->user->create(
    {
	username => $manipulate_user,
	domain   => 'zse1.ru',
	passwd   => 'qwerty',
	passwd2  => 'qwerty',
	email    => 'test@example.com',
	ip       => '127.0.0.1',
	package  => 'newpackage',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::create' );

%answer = (
  text    => 'Cannot Create Account',
  error   => 1,
  details => 'That username already exists on the system'
);
	
$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->create(
    {
	username => $manipulate_user,
	domain   => 'zse1.ru',
	passwd   => 'qwerty',
	passwd2  => 'qwerty',
	email    => 'test@example.com',
	ip       => '127.0.0.1',
	package  => 'newpackage',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::create repeat');

%answer = (
    text 	=> 'Password Changed',
    error 	=> 0,
    details 	=> 'Password successfully changed'
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->change_password(
    {
	user => $manipulate_user,
	pass => 'sdfdsfsdfhsdfj',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::change_password');

%answer = (
    text 	=> 'Success',
    error 	=> 0,
    details 	=> 'All selected Users have been suspended',
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->disable(
    {
	user   => $manipulate_user,
	reason => 'test reason1',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::disable');

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->enable(
    {
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::enable');

$da->{fake_answer} = ! $ONLINE ? { list => ['default','admin'], error => 0, } : undef;

$result = $da->user->list();
ok( ref $result eq 'ARRAY' && scalar @$result, 'API::DirectAdmin::User::list');

%answer = (
    text 	=> 'No such package newpackage on server',
    error 	=> 1,
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->change_package(
    {
	user    => $manipulate_user,
	package => 'newpackage',
    }
);

is_deeply( $result, \%answer, 'API::DirectAdmin::User::change_package');

%answer = (
    text 	=> 'Users deleted',
    error 	=> 0,
    details 	=> "User $manipulate_user Removed",
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->delete(
    {
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::User::delete');

%answer = (
    text 	=> 'Error while deleting Users',
    error 	=> 1,
    details 	=> "User $manipulate_user did not exist on the server.  Removing it from your list.",
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->user->delete(
    {
	user => $manipulate_user,
    }
);
is_deeply( $result, \%answer , 'API::DirectAdmin::User::delete repeat');

# Mysql

use_ok('API::DirectAdmin::Mysql');

$connection_params{auth_user} .= '|' . $manipulate_user;

%answer = (
    text 	=> 'Database Created',
    error 	=> 0,
    details 	=> 'Database Created',
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;

$result = $da->mysql->adddb(
    {
        name     => 'default',
        user     => 'default',
        passwd   => 'default_pass',
        passwd2  => 'default_pass',
    }
);
is_deeply( $result, \%answer, 'API::DirectAdmin::Mysql::adddb');

# Domain

use_ok('API::DirectAdmin::Domain');

my $addondomain = 'ssssss.ru';

%answer = (
    text 	=> 'Domain Created',
    error 	=> 0,
    details 	=> 'Domain Created Successfully'
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;
$result = $da->domain->add(
    {
        domain => $addondomain,
        php => 'ON',
        cgi => 'ON',
    }
);
is_deeply( $result, \%answer  , 'API::DirectAdmin::Domain::add');

%answer = (
    text 	=> 'Cannot create that domain',
    error 	=> 1,
    details 	=> 'That domain already exists'
);

$da->{fake_answer} = ! $ONLINE ? \%answer : undef;
$result = $da->domain->add(
    {
        domain => $addondomain,
        php => 'ON',
        cgi => 'ON',
    }
);
is_deeply( $result, \%answer  , 'API::DirectAdmin::Domain::add repeat');

