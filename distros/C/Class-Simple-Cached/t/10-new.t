#!perl -wT

use strict;
use warnings;

use Test::Most tests => 8;

BEGIN {
	use_ok('Class::Simple::Cached');
}

throws_ok { Class::Simple::Cached->new() } qr /^Usage: /, 'Cache is a required argument to new()';
throws_ok { Class::Simple::Cached->new(1) } qr /Cache must be ref to HASH or object/, 'Cache cannot be a number';
throws_ok { Class::Simple::Cached->new(\'foo') } qr /Cache must be ref to HASH or object/, 'Cache cannot be a ref to a scalar';
throws_ok { Class::Simple::Cached->new(cache => 'foo') } qr /Cache must be ref to HASH or object/, 'Cache cannot be a scalar';
isa_ok(Class::Simple::Cached->new(cache => {}), 'Class::Simple::Cached', 'Creating Class::Simple::Cached object');
isa_ok(Class::Simple::Cached->new(cache => {})->new(), 'Class::Simple::Cached', 'Cloning Class::Simple::Cached object');
ok(!defined(Class::Simple::Cached::new()));
