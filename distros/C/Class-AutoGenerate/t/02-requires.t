#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
use lib 't';

package TestApp::Uses;
use Class::AutoGenerate -base;

requiring 'TestApp::Thing' => generates {
    requires 'TestApp::Other', 'Something';
};

requiring 'TestApp::AnotherThing' => generates {
    requires 'TestApp::AnotherOther';
};

requiring 'TestApp::YetAnotherThing' => generates {
    requires 'TestApp/YetAnotherOther.pm';
};

package main;
TestApp::Uses->new;

require_ok('TestApp::Thing');
require_ok('TestApp::AnotherThing');
require_ok('TestApp::YetAnotherThing');
