#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use Test::MockObject;
use IO::String;

use Auth::Kokolores::Request;

my $server = Test::MockObject->new;
$server->set_isa('Auth::Kokolores', 'Net::Server');

my $r;
lives_ok {
  $r = Auth::Kokolores::Request->new(
    username => 'user',
    password => 'secret',
    server => $server,
  );
} 'create Auth::Kokolores::Request object';
isa_ok( $r, 'Auth::Kokolores::Request');

cmp_ok( $r->username, 'eq', 'user', '->user must be "user"');
cmp_ok( $r->password, 'eq', 'secret', '->password must be "secret"');

