#!perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Auth::Kokolores::Response;

my $r;
lives_ok {
  $r = Auth::Kokolores::Response->new(
    success => 1,
  );
} 'create Auth::Kokolores::Response object';
isa_ok( $r, 'Auth::Kokolores::Response');
cmp_ok( $r->success, 'eq', 1, '->success must be 1');

lives_ok {
  $r = Auth::Kokolores::Response->new_success;
} 'create Auth::Kokolores::Response object';
isa_ok( $r, 'Auth::Kokolores::Response');
cmp_ok( $r->success, 'eq', 1, '->success must be 1');

lives_ok {
  $r = Auth::Kokolores::Response->new_fail;
} 'create Auth::Kokolores::Response object';
isa_ok( $r, 'Auth::Kokolores::Response');
cmp_ok( $r->success, 'eq', 0, '->success must be 0');


