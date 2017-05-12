#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;
use Test::MockObject;

use Auth::Kokolores::Request;
use Auth::Kokolores::Plugin::CheckPassword;

my $server = Test::MockObject->new;
$server->set_isa('Auth::Kokolores', 'Net::Server');
$server->mock( 'log',
  sub {
    my ( $self, $level, $message ) = @_;
    print '# LOG('.$level.'): '.$message."\n"
  }
);

my $r;
lives_ok {
  $r = Auth::Kokolores::Request->new(
    server => $server,
    username => 'user',
    password => 'secret',
    realm => '',
    service => '',
  );
} 'create Auth::Kokolores::Request object';
isa_ok( $r, 'Auth::Kokolores::Request');

## Test PLAIN passwords

my $p;
lives_ok {
  $p = Auth::Kokolores::Plugin::CheckPassword->new(
    server => $server,
    name => 'checkpw',
    method => 'plain',
    password_from => 'password',
  );
} 'create Auth::Kokolores::Plugin::CheckPassword object with plain';
isa_ok( $p, 'Auth::Kokolores::Plugin::CheckPassword');

$r->set_info('password' => 'secret');
my $result;
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 1, 'authentication must be successfull' );

$r->set_info('password' => 'wrong');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 0, 'authentication must fail' );

## Test bcrypt password hash

lives_ok {
  $p = Auth::Kokolores::Plugin::CheckPassword->new(
    server => $server,
    name => 'checkpw',
    method => 'bcrypt',
    password_from => 'password',
  );
  $p->init;
} 'create Auth::Kokolores::Plugin::CheckPassword object with bcrypt';
isa_ok( $p, 'Auth::Kokolores::Plugin::CheckPassword');

$r->set_info('password' => '$2a$10$FQYUbxRjPHTSrrPYN/LCGeEnz4z97hI7uVFjylqAXZuDdMN3NdWne');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 1, 'authentication must be successfull' );

$r->set_info('password' => '$2a$10$FQYUbxRjPHTSrrPYN/LCGekJLedc8pvyQjT0WomapHr9JbfF6zZ3i');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 0, 'authentication must fail' );

## Test pbkdf2 method

lives_ok {
  $p = Auth::Kokolores::Plugin::CheckPassword->new(
    server => $server,
    name => 'checkpw',
    method => 'pbkdf2',
    password_from => 'password',
  );
  $p->init;
} 'create Auth::Kokolores::Plugin::CheckPassword object with pbkdf2';
isa_ok( $p, 'Auth::Kokolores::Plugin::CheckPassword');

$r->set_info('password' => '{X-PBKDF2}HMACSHA1:AAAD6A:djB33Q==:yv04mLWEu7/NzQNV+i6QVN67oqE=');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 1, 'authentication must be successfull' );

$r->set_info('password' => '{X-PBKDF2}HMACSHA1:AAAD6A:bLoUhA==:XpzaWLTiDwV+Ie2M97G41nJXWhg=');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 0, 'authentication must fail' );

