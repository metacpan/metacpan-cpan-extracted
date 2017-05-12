#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
	use_ok('Catalyst::Plugin::Server::JSONRPC::Batch') or print("Bail out!\n");
}

diag("Testing Catalyst::Plugin::Server::JSONRPC::Batch $Catalyst::Plugin::Server::JSONRPC::Batch::VERSION, Perl $], $^X");
