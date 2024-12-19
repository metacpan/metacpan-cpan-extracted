#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 8;

# Load the module being tested
BEGIN { use_ok('CGI::Info') }

local %ENV;
$ENV{'SCRIPT_NAME'} = 'test_script';
$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0';

# Test object creation
my $cgi_info = CGI::Info->new();
ok($cgi_info, 'CGI::Info object created');

# Test script_name method
can_ok($cgi_info, 'script_name');
my $script_name = $cgi_info->script_name();
is($script_name, $ENV{'SCRIPT_NAME'}, 'script_name matches the environment variable');

# Test host_name method
can_ok($cgi_info, 'host_name');
like($cgi_info->host_name(), qr/\w+/, 'host_name returns a valid string');

# Test is_mobile method
can_ok($cgi_info, 'is_mobile');
is($cgi_info->is_mobile(), 0, 'is_mobile returns false by default (not a mobile device)');
