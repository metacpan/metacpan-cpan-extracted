#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 16;

package TestApp::Requiring::Regex;
use Class::AutoGenerate -base;

our @expected_1 = qw( Delta Columbia Vostok R E);
our @expected_2 = qw( 1234 8 );

my $count_1 = 0;
my $count_2 = 0;

requiring qr/^TestApp::(\w+)$/ => generates {
    Test::More::is($1, $expected_1[$count_1++], "require $count_1");
};

requiring qr/^(\w)(\d+)::Auto$/    => generates {
    Test::More::is($1, $expected_1[$count_1++], "require $count_1");
    Test::More::is($2, $expected_2[$count_2++], "require $count_2");
};

package main;
TestApp::Requiring::Regex->new;

require 't/util.pl';

require_ok('TestApp::Delta');
require_ok('TestApp::Columbia');
require_ok('TestApp::Vostok');

require_not_ok('Snoopy::Delta');
require_not_ok('TestApp::Snoopy::Columbia');
require_not_ok('Snoopy::Vostok');

require_ok('R1234::Auto');
require_ok('E8::Auto');

require_not_ok('XYZ::Auto');
