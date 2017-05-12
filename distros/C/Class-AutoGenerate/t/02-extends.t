#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 4;

package TestApp::Base;

sub new { bless {}, shift }

package TestApp::Extends;
use Class::AutoGenerate -base;

requiring 'TestApp::Thing' => generates {
    extends 'TestApp::Base';
};

package main;
TestApp::Extends->new;

require_ok('TestApp::Thing');
can_ok('TestApp::Thing', 'new');
isa_ok(TestApp::Thing->new, 'TestApp::Thing');
isa_ok(TestApp::Thing->new, 'TestApp::Base');
