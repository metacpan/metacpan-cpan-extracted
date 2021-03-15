#!/usr/bin/perl

use Test::More tests => 2;
use Alien::ProtoBuf;

Alien::ProtoBuf->cflags;
Alien::ProtoBuf->libs;
ok(1, 'survived');

ok(Alien::ProtoBuf->libs, 'we got some libs');
