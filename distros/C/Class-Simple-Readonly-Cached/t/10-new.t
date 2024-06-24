#!perl -wT

use strict;

use lib 'lib';
use Test::Most tests => 3;
use Class::Simple::Readonly::Cached;

isa_ok(Class::Simple::Readonly::Cached->new(cache => {}), 'Class::Simple::Readonly::Cached', 'Creating Class::Simple::Readonly::Cached object');
isa_ok(Class::Simple::Readonly::Cached->new(cache => {})->new(), 'Class::Simple::Readonly::Cached', 'Cloning Class::Simple::Readonly::Cached object');
ok(!defined(Class::Simple::Readonly::Cached::new(cache => {})));
