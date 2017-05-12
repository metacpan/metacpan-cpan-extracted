#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::Constants xml => File::Spec->catdir('t', 'confs', 'conf4a.xml');

use t::lib::Bar::Baz;

is(Bar::Baz::test_FOO(), 'Bar::Baz -> FOO is (42)', '... got the right config variable');