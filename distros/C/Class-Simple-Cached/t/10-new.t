#!perl -wT

use strict;
use warnings;

use Test::Most tests => 7;

BEGIN {
	use_ok('Class::Simple::Cached');
}

ok(!defined(Class::Simple::Cached->new()));
ok(!defined(Class::Simple::Cached->new(1)));
ok(!defined(Class::Simple::Cached->new(\'foo')));
ok(!defined(Class::Simple::Cached->new(cache => 'foo')));
isa_ok(Class::Simple::Cached->new(cache => {}), 'Class::Simple::Cached', 'Creating Class::Simple::Cached object');
ok(!defined(Class::Simple::Cached::new()));
