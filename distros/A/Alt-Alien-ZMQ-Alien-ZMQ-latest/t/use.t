#!/usr/bin/env perl

use Test::Most tests => 1;

use Alien::ZMQ;

subtest "Use Alt Alien::ZMQ" => sub {
	is( Alien::ZMQ->_source, 'Alien::ZMQ::latest', 'using the alt Alien::ZMQ');
};

done_testing;
