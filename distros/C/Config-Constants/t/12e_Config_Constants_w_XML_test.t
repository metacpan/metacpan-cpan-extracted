#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

use Config::Constants xml => File::Spec->catdir('t', 'confs', 'conf4.xml');

use t::lib::Bar::Baz;

is(Bar::Baz::test_FOO(), 'Bar::Baz -> FOO is (50)', '... got the right config variable');
is(Bar::Baz::test_BAR(), 'Bar::Baz -> BAR is (Foo and Baz)', '... got the right config variable');