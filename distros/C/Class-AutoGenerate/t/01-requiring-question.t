#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 16;

package TestApp::Requiring::SingleQuestion;
use Class::AutoGenerate -base;

our @expected_1 = qw( A B C G H K );

my $count = 0;
requiring 'TestApp::?' => generates {
    Test::More::is($1, $expected_1[$count++], "require $count");
};

requiring '?::Auto'    => generates {
    Test::More::is($1, $expected_1[$count++], "require $count");
};

package main;
TestApp::Requiring::SingleQuestion->new;

require 't/util.pl';

require_ok('TestApp::A');
require_ok('TestApp::B');
require_ok('TestApp::C');

require_not_ok('D::A');
require_not_ok('TestApp::EF');
require_not_ok('D::C');

require_ok('G::Auto');
require_ok('H::Auto');

require_not_ok('IJ::Auto');

require_ok('K::Auto');
