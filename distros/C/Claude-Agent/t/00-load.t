#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

my @modules = qw(
    Claude::Agent
    Claude::Agent::Options
    Claude::Agent::Message
    Claude::Agent::Content
    Claude::Agent::Query
    Claude::Agent::Error
    Claude::Agent::Hook
    Claude::Agent::Permission
    Claude::Agent::MCP
    Claude::Agent::Subagent
    Claude::Agent::Client
);

plan tests => scalar @modules;

for my $module (@modules) {
    use_ok($module) || print "Bail out! Cannot load $module\n";
}

diag( "Testing Claude::Agent $Claude::Agent::VERSION, Perl $], $^X" );
