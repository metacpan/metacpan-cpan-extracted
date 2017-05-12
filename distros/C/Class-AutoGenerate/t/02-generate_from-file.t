#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;

package TestApp::GenerateFrom::File;
use Class::AutoGenerate -base;

requiring 'TestApp::Auto' => generates {
    generate_from source_file 't/test-source.pl';
};

package main;
TestApp::GenerateFrom::File->new;

require_ok('TestApp::Auto');
TestApp::Auto->pass1;
TestApp::Auto->pass2;
