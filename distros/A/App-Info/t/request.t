#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;
use File::Spec::Functions qw(tmpdir);

BEGIN { use_ok('App::Info::Request') }

ok( my $req = App::Info::Request->new, "New default request" );
isa_ok($req, 'App::Info::Request');
eval {  App::Info::Request->new('foo') };
like( $@,
      qr/^Odd number of parameters in call to App::Info::Request->new\(\)/,
      "Catch invalid params" );
eval {  App::Info::Request->new( callback => 'foo' ) };
like( $@, qr/^Callback parameter 'foo' is not a code reference/,
      "Catch invalid callback" );


# Now create a request we can actually use for testing stuff.
my %args = (
    message  => 'Enter a value',
    callback => sub { ref $_[0] eq 'HASH' && $_[0]->{val} == 1 },
    error    => 'Invalid value',
    type     => 'info',
    key      => 'value',
);

ok( $req = App::Info::Request->new( %args ), "New custom request" );
is( $req->key, $args{key}, "Check key" );
is( $req->message, $args{message}, "Check message" );
is( $req->error, $args{error}, "Check error" );
is( $req->type, $args{type}, "Check type" );

ok( !$req->callback('foo'),  "Fail callback" );
my $val = { val => 1 };
ok( $req->callback($val), "Succeed callback" );
ok( ! $req->value({ val => 0 }), "Fail value" );
ok( $req->value($val), "Succeed value" );
is( $req->value, $val, "Check value" );

# Try changing the callback to use $_.
$args{callback} = sub { -d };
ok( $req = App::Info::Request->new( %args ), "Another custom request" );
ok( $req->callback(tmpdir), 'Try $_ callback');
ok( !$req->callback('foo234234'),  'Fail $_ callback' );
