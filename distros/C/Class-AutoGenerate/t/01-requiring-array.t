#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 17;

package TestApp::Requiring::Array;
use Class::AutoGenerate -base;

my @planets = qw( Mercury Venus Earth Mars Jupiter Saturn Uranus Neptune );

my $count = 0;
requiring [ map { 'Planets::'.$_ } @planets ] => generates {
    Test::More::is($1, 'Planets::'.$planets[$count++]);
};

package main;
TestApp::Requiring::Array->new;

require 't/util.pl';

require_ok('Planets::Mercury');
require_ok('Planets::Venus');
require_ok('Planets::Earth');
require_ok('Planets::Mars');
require_ok('Planets::Jupiter');
require_ok('Planets::Saturn');
require_ok('Planets::Uranus');
require_ok('Planets::Neptune');
require_not_ok('Planets::Pluto'); # pluto was a planet when i grew up
