#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

use_ok($_) for qw(
    App::MCP::CLI
    App::MCP::CLI::Client
    App::MCP::CLI::Config
    App::MCP::CLI::Command::list
    App::MCP::CLI::Command::call
    App::MCP::CLI::Command::interactive
    App::MCP::CLI::Command::servers
    App::MCP::CLI::Command::version
);

diag( "Testing App::MCP::CLI $App::MCP::CLI::VERSION, Perl $], $^X" );
