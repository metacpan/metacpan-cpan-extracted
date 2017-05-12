#!/usr/bin/env perl

use lib::abs 'lib';
use Dancer::Test;
use MyApp;
use Test::More tests => 2;


response_status_is 
	[ GET => '/' ] =>  200,
	'found';

response_status_is
	[ GET => '/x' ] => 404,
	'not found';

