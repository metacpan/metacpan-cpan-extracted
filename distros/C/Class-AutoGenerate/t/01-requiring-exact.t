#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;

package TestApp::Requiring::Exact;
use Class::AutoGenerate -base;

requiring 'TestApp::Auto' => generates {
    Test::More::is($1, 'TestApp::Auto');
};

package main;
TestApp::Requiring::Exact->new;

require 't/util.pl';

require_ok('TestApp::Auto');
require_not_ok('TestApp::Blah');

1;

