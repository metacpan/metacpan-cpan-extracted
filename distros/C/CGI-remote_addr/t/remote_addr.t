#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use CGI;
use CGI::remote_addr;

###############################################################################
### Clear our environment; we'll set it up locally as needed.
###############################################################################
delete $ENV{HTTP_X_FORWARDED_FOR};
delete $ENV{REMOTE_ADDR};

###############################################################################
# Return empty handed if NO IP information available
subtest 'empty_handed_if_no_ip_available' => sub {
    my $cgi = CGI->new('');
    my $ip  = $cgi->remote_addr();
    ok !defined $ip, 'undef if no IP available';
};

###############################################################################
# Return IP from REMOTE_ADDR if that's all we've got
subtest 'remote_addr' => sub {
    local $ENV{REMOTE_ADDR} = '127.0.0.1';
    my $cgi = CGI->new('');
    my $ip  = $cgi->remote_addr();
    is $ip, '127.0.0.1', 'use REMOTE_ADDR if available';
};

###############################################################################
# Prefer IP from HTTP_X_FORWARDED_FOR if available
subtest 'http_x_forwarded_for' => sub {
    local $ENV{REMOTE_ADDR} = '127.0.0.1';
    local $ENV{HTTP_X_FORWARDED_FOR} = '192.168.0.1';
    my $cgi = CGI->new('');
    my $ip  = $cgi->remote_addr();
    is $ip, '192.168.0.1', 'prefer HTTP_X_FORWARDED_FOR if available';
};

###############################################################################
# Only return valid IPs
subtest 'only_valid_ips' => sub {
    local $ENV{HTTP_X_FORWARDED_FOR} = '<unknown>, 127.0.0.1';
    my $cgi = CGI->new('');
    my $ip  = $cgi->remote_addr();
    is $ip, '127.0.0.1', 'only valid IPs returned';
};

###############################################################################
# Return in scalar context
subtest 'scalar_context' => sub {
    local $ENV{REMOTE_ADDR} = '127.0.0.1';
    local $ENV{HTTP_X_FORWARDED_FOR} = '192.168.0.1';
    my $cgi = CGI->new('');
    my $ip  = $cgi->remote_addr();
    is $ip, '192.168.0.1', 'scalar context';
};

###############################################################################
# Return in list context
subtest 'list_context' => sub {
    local $ENV{REMOTE_ADDR} = '127.0.0.1';
    local $ENV{HTTP_X_FORWARDED_FOR} = '192.168.0.1';
    my $cgi = CGI->new('');
    my @ips = $cgi->remote_addr();
    is scalar @ips, 2, 'list context contains 2 entries';
    is $ips[0], '192.168.0.1', '... HTTP_X_FORWARDED_FOR is first';
    is $ips[1], '127.0.0.1',   '... REMOTE_ADDR is second';
};

###############################################################################
# List context is unique
subtest 'list_context_is_unique' => sub {
    local $ENV{REMOTE_ADDR} = '127.0.0.1';
    local $ENV{HTTP_X_FORWARDED_FOR} = '192.168.0.1, 127.0.0.1';
    my $cgi = CGI->new('');
    my @ips = $cgi->remote_addr();
    is scalar @ips, 2, 'list context contains 2 unique entries';
};

###############################################################################
done_testing();
