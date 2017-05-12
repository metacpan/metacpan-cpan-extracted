#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 18;

package TestApp::Requiring::DoubleAsterisk;
use Class::AutoGenerate -base;

our @expected_1 = qw(
    Delta Columbia Vostok Snoopy::Columbia
    Redstone EdWhite Delta7::TestApp Auto
);

my $count = 0;
requiring 'TestApp::**' => generates {
    Test::More::is($1, $expected_1[$count++], "require $count");
};

requiring '**::Auto'    => generates {
    Test::More::is($1, $expected_1[$count++], "require $count");
};

package main;
TestApp::Requiring::DoubleAsterisk->new;

require 't/util.pl';

require_ok('TestApp::Delta');
require_ok('TestApp::Columbia');
require_ok('TestApp::Vostok');

require_not_ok('Snoopy::Delta');
require_ok('TestApp::Snoopy::Columbia');
require_not_ok('Snoopy::Vostok');

require_ok('Redstone::Auto');
require_ok('EdWhite::Auto');

require_ok('Delta7::TestApp::Auto');

require_ok('TestApp::Auto');
