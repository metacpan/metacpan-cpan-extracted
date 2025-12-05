#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);

my $dnsq = "$RealBin/../bin/dnsq";

# Check if dnsq exists and is executable
ok(-x $dnsq, "dnsq is executable");

# Test basic query
my $output = `$dnsq --short google.com 2>/dev/null`;
ok($output =~ /^\d+\.\d+\.\d+\.\d+$/, "Basic A query returns IP address");

# Test JSON output
$output = `$dnsq --json --short google.com 2>/dev/null`;
ok($output =~ /"domain":"google\.com"/, "JSON output contains domain");
ok($output =~ /"type":"A"/, "JSON output contains type");

# Test MX query
$output = `$dnsq --short google.com MX 2>/dev/null`;
ok($output =~ /smtp\.google\.com/, "MX query returns mail server");

# Test custom server
$output = `$dnsq -s 8.8.8.8 --short google.com 2>/dev/null`;
ok($output =~ /^\d+\.\d+\.\d+\.\d+$/, "Custom server query works");

# Test help
$output = `$dnsq --help 2>&1`;
ok($output =~ /USAGE:/, "Help output works");

# Test version
$output = `$dnsq --version 2>&1`;
ok($output =~ /dnsq version/, "Version output works");

done_testing();
