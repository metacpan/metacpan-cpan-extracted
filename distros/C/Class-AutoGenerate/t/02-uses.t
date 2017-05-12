#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 6;
use lib 't';

package TestApp::Uses;
use Class::AutoGenerate -base;

requiring 'TestApp::Thing' => generates {
    uses 'TestApp::Other', 'Something';
};

requiring 'TestApp::AnotherThing' => generates {
    uses 'TestApp::AnotherOther';
};

package main;
TestApp::Uses->new;

require_ok('TestApp::Thing');
require_ok('TestApp::AnotherThing');
