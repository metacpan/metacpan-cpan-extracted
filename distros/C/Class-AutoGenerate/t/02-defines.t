#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 6;

package TestApp::Defines;
use Class::AutoGenerate -base;

requiring 'TestApp::Auto' => generates {
    defines '$scalar' => 42;
    defines '@array'  => [ 1, 2, 3 ];
    defines '%hash'   => { a => 1, b => 2, c => 3 };

    defines 'pass1'   => sub { Test::More::pass(); };
    defines '&pass2'  => sub { Test::More::pass(); };
};

package main;
TestApp::Defines->new;

no warnings 'once';

require_ok('TestApp::Auto');

is($TestApp::Auto::scalar, 42);
is_deeply(\@TestApp::Auto::array, [ 1, 2, 3 ]);
is_deeply(\%TestApp::Auto::hash, { a => 1, b => 2, c => 3 });

TestApp::Auto->pass1;
TestApp::Auto->pass2;

1;
