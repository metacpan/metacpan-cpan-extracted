#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;

package TestApp::GenerateFrom::Source;
use Class::AutoGenerate -base;

requiring 'TestApp::Auto' => generates {
    generate_from "sub pass1 { Test::More::pass(); }";
    generate_from source_code "sub pass2 { Test::More::pass(); }";
};

package main;
TestApp::GenerateFrom::Source->new;

require_ok('TestApp::Auto');
TestApp::Auto->pass1;
TestApp::Auto->pass2;
